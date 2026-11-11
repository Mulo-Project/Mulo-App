package com.mulo.app

import org.json.JSONObject
import java.io.File
import java.net.URLEncoder
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/** yt-dlp 실행 결과 하나. */
class YtDlpRun(val exitCode: Int, val stdout: String, val stderr: String)

/** yt-dlp를 실제로 돌리는 쪽 (full 빌드는 youtubedl-android, lite 빌드는 못 돌린다). 마지막 인자는 주소다. */
interface YtDlpRunner {
    val available: Boolean

    /** [id]로 구분되는 실행 하나. 진행률(0 ~ 1)은 [onProgress]로. 돌릴 수 없으면 `unavailable` 오류를 던진다. */
    fun run(args: List<String>, id: String, onProgress: ((Double) -> Unit)? = null): YtDlpRun

    /** 시간 초과로 포기한 실행을 끊는다. */
    fun cancel(id: String): Boolean
}

/** 오류 코드를 단 yt-dlp 엔진 예외 (코드는 Dart `EngineFailure` 이름과 같다). */
class YtDlpException(code: String, message: String) : NativeChannel.CodedException(code, message)

/**
 * 로컬 엔진: yt-dlp로 검색 · 곡 정보 · 재생 주소 · 자막 · 영상 저장을 한다 (예전 Dart `LocalEngine`을 옮겼다).
 * 호출은 모두 막는(동기) 함수라 채널의 백그라운드 스레드에서 부른다. 짧은 호출은 [ExecGate]로 한 번에 하나씩 돈다.
 * 영상 파일 받기([saveVideo])는 몇 분 걸려서 줄 밖에서 따로 돈다.
 */
class YtDlpEngine(
    private val runner: YtDlpRunner,
    private val tempDir: () -> File,
    private val timeoutMs: Long = 60_000,
    private val saveTimeoutMs: Long = 30 * 60_000,
    private val readPage: (String) -> String? = ::fetchPage,
) {
    private val gate = ExecGate()
    private val watchdog = Executors.newCachedThreadPool()
    private var seq = 0

    val available get() = runner.available

    private fun nextId(): String = synchronized(this) { "engine${seq++}" }

    /** 사이트 검색은 쪽 개념이 없어서 (page+1)*size개를 받아 해당 쪽만 자른다. [prefix]는 `ytsearch` 같은 검색 키. */
    fun search(prefix: String, query: String, page: Int, size: Int): Map<String, Any?> {
        val want = (page + 1) * size
        MuloLog.d(MuloLog.NATIVE, "yt-dlp 검색 $prefix$want:$query")
        val out = exec(listOf("--flat-playlist", "--dump-json", "--no-warnings", "$prefix$want:$query"))
        val all = ArrayList<Map<String, Any?>>()
        for (line in out.lineSequence()) decode(line)?.let { all.add(YtDlpParsers.hit(it)) }
        return paged(all, page, size, want)
    }

    /** 유튜브 검색 결과 쪽의 "재생목록" 필터 주소를 목록으로 읽는다. */
    fun searchPlaylists(query: String, page: Int, size: Int): Map<String, Any?> {
        val want = (page + 1) * size
        val url = "https://www.youtube.com/results?search_query=" + URLEncoder.encode(query, "UTF-8") +
            "&sp=" + URLEncoder.encode("EgIQAw%3D%3D", "UTF-8")
        val out = exec(listOf("--flat-playlist", "--dump-json", "--no-warnings", "--playlist-end", "$want", url))
        val all = ArrayList<Map<String, Any?>>()
        for (line in out.lineSequence()) decode(line)?.let { j -> YtDlpParsers.playlistHit(j)?.let { all.add(it) } }
        return paged(all, page, size, want)
    }

    private fun paged(all: List<Map<String, Any?>>, page: Int, size: Int, want: Int): Map<String, Any?> {
        val start = page * size
        return mapOf("items" to if (start >= all.size) emptyList() else all.subList(start, all.size), "hasNext" to (all.size >= want))
    }

    /** 곡 · 재생목록 정보. 곡 정보에는 필요 없는 DASH · HLS 목록과 번역 자막을 받지 않아 더 빠르다. */
    fun info(url: String): Map<String, Any?> {
        val out = exec(
            listOf("--flat-playlist", "--dump-single-json", "--no-warnings", "--extractor-args", "youtube:skip=dash,hls,translated_subs", url),
        )
        return YtDlpParsers.info(decode(out) ?: throw YtDlpException("failed", "bad response"))
    }

    /**
     * 채널 정보. 채널 탭의 영상은 받지 않고(`--playlist-items 0`) 채널 자체 정보만 읽는다.
     * SoundCloud는 yt-dlp 정보에 프로필 이미지가 없거나 이름이 달라 비는 일이 있어서, 비면 아티스트 페이지의
     * `og:image`를 읽어 채운다 (yt-dlp가 못 읽어도 이미지는 읽어 본다).
     */
    fun channel(url: String): Map<String, Any?> {
        var info: Map<String, Any?>? = null
        var failure: YtDlpException? = null
        try {
            val out = exec(listOf("--flat-playlist", "--playlist-items", "0", "--dump-single-json", "--no-warnings", url))
            info = YtDlpParsers.channel(decode(out) ?: throw YtDlpException("failed", "bad response"))
        } catch (e: YtDlpException) {
            if (!YtDlpParsers.isSoundcloud(url)) throw e
            failure = e
        }
        if (info != null && info["thumbnail"] != null) return info
        if (!YtDlpParsers.isSoundcloud(url)) return info!!
        val avatar = readPage(url)?.let { YtDlpParsers.soundcloudAvatarFromHtml(it) }
        if (avatar == null) {
            if (info != null) return info
            throw failure ?: YtDlpException("not_found", "no avatar")
        }
        return mapOf("thumbnail" to avatar, "subscriberCount" to info?.get("subscriberCount"))
    }

    /** 소리 주소. 기본 클라이언트로 못 읽으면 `android_vr`로 한 번 더 시도하고, 그래도 안 되면 첫 오류를 알린다. */
    fun audio(url: String, language: String?): Map<String, Any?> = timed("소리만 읽기") {
        withFallback { extra ->
            val out = exec(
                listOf("-f", YtDlpParsers.audioSelector(language), "--no-playlist", "--dump-single-json", "--no-warnings") + extra + url,
                priority = 0,
            )
            decode(out)?.let { YtDlpParsers.audio(it) } ?: throw YtDlpException("failed", "bad response")
        }
    }

    /** 영상 주소 (소리가 든 형식을 먼저, 없으면 영상 전용). 예전 화면을 위한 읽기는 새 요청이 오면 줄에서 빠진다. */
    fun video(url: String, maxHeight: Int): Map<String, Any?> = timed("영상만 읽기") {
        withFallback { extra ->
            val out = exec(
                listOf("-f", YtDlpParsers.videoSelector(maxHeight), "--no-playlist", "--dump-single-json", "--no-warnings") + extra + url,
                priority = 1,
                group = "video",
            )
            decode(out)?.let { YtDlpParsers.video(it) } ?: throw YtDlpException("failed", "bad response")
        }
    }

    private fun <T> withFallback(read: (List<String>) -> T): T {
        try {
            return read(emptyList())
        } catch (first: YtDlpException) {
            if (first.code != "failed" || first.message == "superseded") throw first
            // 기본 클라이언트로는 오디오 형식을 못 읽는 경우가 있다 (JS 실행기가 없는 환경 등).
            try {
                return read(listOf("--extractor-args", "youtube:player_client=android_vr"))
            } catch (_: YtDlpException) {
                throw first
            }
        }
    }

    private fun <T> timed(label: String, block: () -> T): T {
        val start = System.currentTimeMillis()
        try {
            return block()
        } finally {
            MuloLog.d(MuloLog.NATIVE, "$label ${System.currentTimeMillis() - start}ms")
        }
    }

    /** 형식 목록에서 오디오 트랙 언어를 읽는다. 하나뿐이면 빈 목록. */
    fun audioLanguages(url: String): List<Map<String, Any?>> {
        val out = exec(listOf("--dump-single-json", "--no-playlist", "--no-warnings", "--skip-download", url))
        return decode(out)?.let { YtDlpParsers.audioLanguages(it) } ?: emptyList()
    }

    /** 어떤 자막이 있는지 먼저 읽고, 고른 언어 한 벌만 받는다 (모든 언어를 받지 않으려고). 쓸 자막이 없으면 null. */
    fun subtitles(url: String, prefer: List<String>): Map<String, Any?>? {
        val j = decode(exec(listOf("--dump-single-json", "--no-playlist", "--no-warnings", "--skip-download", url)))
            ?: throw YtDlpException("failed", "bad response")
        val (language, automatic) = YtDlpParsers.pickSubtitleLanguage(
            YtDlpParsers.keys(j.opt("subtitles")),
            YtDlpParsers.originalAutoKeys(j.opt("automatic_captions")),
            prefer,
        ) ?: return null
        val dir = tempDir()
        try {
            dir.mkdirs()
            exec(
                listOf(
                    "--skip-download", "--no-playlist", "--no-warnings",
                    if (automatic) "--write-auto-subs" else "--write-subs",
                    "--sub-langs", language, "--sub-format", "vtt",
                    "-o", File(dir, "sub").path, url,
                ),
            )
            val file = dir.listFiles { f -> f.isFile && f.name.endsWith(".vtt") }?.firstOrNull() ?: return null
            val cues = YtDlpParsers.parseVtt(file.readText())
            if (cues.isEmpty()) return null
            return mapOf("language" to language, "automatic" to automatic, "cues" to cues)
        } finally {
            dir.deleteRecursively()
        }
    }

    /**
     * 영상(+소리)을 받아 [dir]/[stem].[extension]으로 합쳐 둔다 (APK에 든 ffmpeg 사용). 몇 분 걸리는 일이라
     * 짧은 호출의 줄에 서지 않고 바로 돈다. 못 받으면 [YtDlpException]. [onProgress]는 0 ~ 1.
     */
    fun saveVideo(url: String, maxHeight: Int, extension: String, dir: File, stem: String, onProgress: (Double) -> Unit) {
        if (!runner.available) throw YtDlpException("unavailable", "yt-dlp")
        val id = nextId()
        val args = listOf(
            "-f", YtDlpParsers.saveSelector(maxHeight, extension),
            "--merge-output-format", extension,
            "--no-playlist", "--no-warnings", "--newline",
            "-o", File(dir, "$stem.%(ext)s").path, url,
        )
        val r = runWithTimeout(id, saveTimeoutMs) { runner.run(args, id, onProgress) }
        if (r.exitCode != 0) throw YtDlpException("failed", r.stderr.trim())
    }

    private fun decode(s: String): JSONObject? {
        if (s.isBlank()) return null
        return try {
            JSONObject(s)
        } catch (_: Exception) {
            null
        }
    }

    private fun exec(args: List<String>, priority: Int = 2, group: String? = null): String {
        val label = listOfNotNull(
            args.indexOf("-f").takeIf { it >= 0 && it + 1 < args.size }?.let { "-f ${args[it + 1]}" },
            if (args.contains("--extractor-args")) "extractor-args" else null,
            if (args.contains("--skip-download")) "info" else null,
        ).joinToString(" ")
        return try {
            gate.run(priority, group) { execNow(args, label) }
        } catch (_: ExecGate.SupersededException) {
            throw YtDlpException("failed", "superseded")
        }
    }

    private fun execNow(args: List<String>, label: String): String {
        if (!runner.available) throw YtDlpException("unavailable", "yt-dlp")
        val id = nextId()
        val start = System.currentTimeMillis()
        val r = runWithTimeout(id, timeoutMs) { runner.run(args, id) }
        MuloLog.d(MuloLog.NATIVE, "yt-dlp ${System.currentTimeMillis() - start}ms 종료 ${r.exitCode} [$label]")
        if (r.exitCode != 0) {
            val err = r.stderr.trim()
            MuloLog.d(MuloLog.NATIVE, "yt-dlp 실패(${r.exitCode}): $err")
            throw YtDlpException(YtDlpParsers.failureCode(err), err)
        }
        return r.stdout
    }

    /** [block]을 따로 돌려 [limitMs] 안에 안 끝나면 yt-dlp를 끊고 `timeout`으로 알린다 (멈춘 실행이 줄을 막지 않게). */
    private fun runWithTimeout(id: String, limitMs: Long, block: () -> YtDlpRun): YtDlpRun {
        val future = watchdog.submit<YtDlpRun> { block() }
        return try {
            future.get(limitMs, TimeUnit.MILLISECONDS)
        } catch (_: TimeoutException) {
            runner.cancel(id)
            future.cancel(true)
            throw YtDlpException("timeout", "timeout")
        } catch (e: java.util.concurrent.ExecutionException) {
            val cause = e.cause
            if (cause is YtDlpException) throw cause
            throw YtDlpException("failed", cause?.message ?: "")
        }
    }

    fun dispose() {
        watchdog.shutdownNow()
    }
}

/** 주소의 페이지 머리말을 읽는다 (앞 200KB만). 못 읽으면 null. */
internal fun fetchPage(url: String): String? {
    val c = java.net.URL(url).openConnection() as java.net.HttpURLConnection
    return try {
        c.connectTimeout = 8000
        c.readTimeout = 10000
        c.setRequestProperty(
            "User-Agent",
            "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36",
        )
        if (c.responseCode != 200) return null
        val buf = java.io.ByteArrayOutputStream()
        val chunk = ByteArray(8192)
        c.inputStream.use { input ->
            while (buf.size() <= 200 * 1024) {
                val n = input.read(chunk)
                if (n < 0) break
                buf.write(chunk, 0, n)
            }
        }
        buf.toString("UTF-8")
    } catch (_: Exception) {
        null
    } finally {
        c.disconnect()
    }
}
