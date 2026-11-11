package com.mulo.app

import android.content.Context
import android.util.Base64
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import io.flutter.plugin.common.BinaryMessenger
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/**
 * 오디오 변환(full 빌드): youtubedl-android의 ffmpeg 모듈이 APK에 넣어 둔 ffmpeg를 실행해
 * 받은 오디오를 mp3 · opus로 바꾼다. 라이브러리가 yt-dlp를 돌릴 때와 같은 방식으로
 * `nativeLibraryDir/libffmpeg.so`를 실행 파일로, 풀어 둔 공유 라이브러리를 `LD_LIBRARY_PATH`로 쓴다.
 * lite 빌드는 같은 이름의 빈 구현이 들어가 `available`이 false다.
 */
class TranscoderChannel(private val context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME) {
    private val io = Executors.newSingleThreadExecutor()

    @Volatile private var process: Process? = null
    @Volatile private var ready = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(true)
                "cancel" -> {
                    process?.destroy()
                    result.success(null)
                }
                "convert" -> {
                    val input = call.argument<String>("input")
                    val output = call.argument<String>("output")
                    val codec = call.argument<String>("codec")
                    val bitrate = call.argument<Int>("bitrate")
                    val format = call.argument<String>("format")
                    if (input == null || output == null || codec == null || bitrate == null || format == null) {
                        result.error("bad_args", "input, output, codec, bitrate, format required", null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, "convert_failed") { convert(input, output, codec, bitrate, format) }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * ffmpeg가 찾을 공유 라이브러리 폴더들. 풀어 둔 ffmpeg · 파이썬 패키지의 `usr/lib`에 더해,
     * C++ 런타임(`libc++_shared.so`)이 들어 있는 앱의 네이티브 라이브러리 폴더도 넣는다
     * (없으면 "library libc++_shared.so not found"로 실행이 안 된다).
     */
    private fun libraryPath(): String {
        val packages = File(context.noBackupFilesDir, "youtubedl-android/packages")
        val dirs = listOf(
            File(packages, "ffmpeg/usr/lib").absolutePath,
            File(packages, "python/usr/lib").absolutePath,
            context.applicationInfo.nativeLibraryDir,
        )
        val existing = System.getenv("LD_LIBRARY_PATH")
        return (dirs + listOfNotNull(existing)).joinToString(":")
    }

    private fun ensureInit() {
        if (ready) return
        synchronized(this) {
            if (ready) return
            // ffmpeg가 찾는 C++ 런타임(libc++_shared.so)은 파이썬 패키지 폴더에 들어 있다.
            // yt-dlp를 한 번도 안 돌린 실행(앱 데이터를 지운 뒤 가사 저장 등)에서도 있도록 파이썬부터 푼다.
            YoutubeDL.getInstance().init(context)
            // libffmpeg.zip.so를 앱 전용 폴더에 풀어 둔다 (처음 한 번, 버전이 바뀌면 다시).
            FFmpeg.getInstance().init(context)
            ready = true
        }
    }

    // 태그: 앱(Dart)은 형식을 모른다. [TagChannel]이 [TagFormats]로 형식을 고르고, 이 파일의 형식별 함수를 부른다.
    // 형식마다 다른 것(키 이름 · 커버를 넣는 방식 · 커버를 쓰는지)은 아래 형식별 함수가 각자 정한다.
    // 한 형식의 변경이 다른 형식에 새지 않게 인자는 함수마다 따로 만들고, 공통은 [runFfmpeg] · [entriesOf]뿐이다.
    // 모두 소리 · 영상은 그대로(`-c copy`) 두고, 파일에 있던 태그는 두고 넘어온 칸만 덮어쓴다 (빈 값은 그 칸을 지운다).

    fun isAvailable(): Boolean = true

    /**
     * [input]의 태그를 [values](기본 칸은 소문자 `title` `artist` `album` `genre` `lyrics`, 그 밖은 앱 전용 칸)와
     * 커버 PNG [cover]로 고쳐 [output]에 쓴다. [format]은 [TagFormats]. 성공하면 true (실패하면 예외 또는 false).
     */
    fun tagFile(input: String, values: Map<String, String>, cover: String?, format: String, output: String): Boolean {
        val entries = values.entries.map { it.key to it.value }
        return when (format) {
            TagFormats.MP3 -> tagMp3(input, entries, output, cover)
            TagFormats.MP4 -> tagMp4(input, entries, output, cover)
            TagFormats.WEBM -> tagWebm(input, entries, output)
            TagFormats.M4A -> tagM4a(input, entries, output, cover)
            else -> tagOgg(input, entries, output, cover)
        }
    }

    /** mp3: 대문자 키. 그림이 있으면 첨부 그림(attached_pic, "앞면 커버")으로 붙이고, 없으면 파일의 커버를 그대로 둔다. ID3 v2.3. */
    private fun tagMp3(input: String, values: List<Pair<String, String>>, output: String, cover: String?): Boolean {
        val args = mutableListOf("-nostdin", "-y", "-i", input)
        if (cover != null) args += listOf("-i", cover)
        args += listOf("-map", "0:a")
        if (cover != null) {
            args += listOf(
                "-map", "1:v", "-disposition:v:0", "attached_pic",
                "-metadata:s:v", "title=Album cover", "-metadata:s:v", "comment=Cover (front)",
            )
        } else {
            args += listOf("-map", "0:v?")
        }
        for ((key, value) in entriesOf(values, upper = true)) args += listOf("-metadata", "$key=$value")
        args += listOf("-c", "copy", "-id3v2_version", "3", "-f", "mp3", output)
        return runFfmpeg(args, output)
    }

    /**
     * opus · ogg: 대문자 키(Vorbis 코멘트), 소리 스트림만 넘긴다. 태그는 전체와 첫 소리 스트림 둘 다에 넣는다.
     * 커버는 태그 값 `METADATA_BLOCK_PICTURE`(FLAC 그림 블록을 base64로)에 넣는다. 그림은 값이 커서 명령줄 인자로 넘길 수
     * 없어 ffmetadata 파일로 태그를 통째로 새로 쓴다 (커버를 새로 정하는 곳은 모든 칸을 함께 넘긴다).
     */
    private fun tagOgg(input: String, values: List<Pair<String, String>>, output: String, cover: String?): Boolean {
        val entries = entriesOf(values, upper = true)
        if (cover == null) {
            val args = mutableListOf("-nostdin", "-y", "-i", input, "-map", "0:a")
            for ((key, value) in entries) args += listOf("-metadata", "$key=$value", "-metadata:s:a:0", "$key=$value")
            args += listOf("-c", "copy", "-f", "ogg", output)
            return runFfmpeg(args, output)
        }
        val full = File("$output.full")
        try {
            val picture = Base64.encodeToString(pictureBlock(File(cover).readBytes()), Base64.NO_WRAP)
            full.writeText(ffmetadata(entries + ("METADATA_BLOCK_PICTURE" to picture)), Charsets.UTF_8)
            val args = listOf(
                "-nostdin", "-y", "-i", input, "-i", full.absolutePath, "-map", "0:a",
                "-map_metadata", "1", "-map_metadata:s:a:0", "1:g", "-c", "copy", "-f", "ogg", output,
            )
            return runFfmpeg(args, output)
        } finally {
            full.delete()
        }
    }

    /** mp4 영상: 소문자 키. 전체 스트림을 넘기고, 그림이 있으면 첨부 그림으로 더한다. genre 등 title · artist 밖의 칸도 쓰게 한다. */
    private fun tagMp4(input: String, values: List<Pair<String, String>>, output: String, cover: String?): Boolean {
        val args = mutableListOf("-nostdin", "-y", "-i", input)
        if (cover != null) args += listOf("-i", cover)
        args += listOf("-map", "0")
        if (cover != null) args += listOf("-map", "1:v", "-disposition:v:1", "attached_pic")
        for ((key, value) in entriesOf(values, upper = false)) args += listOf("-metadata", "$key=$value")
        args += listOf("-c", "copy", "-movflags", "+use_metadata_tags", "-f", "mp4", output)
        return runFfmpeg(args, output)
    }

    /** m4a 오디오(mp4 껍데기): 소문자 키, 소리만 넘기고 그림이 있으면 첨부 그림으로 붙인다. */
    private fun tagM4a(input: String, values: List<Pair<String, String>>, output: String, cover: String?): Boolean {
        val args = mutableListOf("-nostdin", "-y", "-i", input)
        if (cover != null) args += listOf("-i", cover)
        args += listOf("-map", "0:a")
        if (cover != null) args += listOf("-map", "1:v", "-disposition:v:0", "attached_pic")
        for ((key, value) in entriesOf(values, upper = false)) args += listOf("-metadata", "$key=$value")
        args += listOf("-c", "copy", "-movflags", "+use_metadata_tags", "-f", "ipod", output)
        return runFfmpeg(args, output)
    }

    /** webm(Matroska) 영상: 소문자 키. 첨부 그림을 쓰지 않아 커버는 무시하고 글 태그만 쓴다. */
    private fun tagWebm(input: String, values: List<Pair<String, String>>, output: String): Boolean {
        val args = mutableListOf("-nostdin", "-y", "-i", input, "-map", "0")
        for ((key, value) in entriesOf(values, upper = false)) args += listOf("-metadata", "$key=$value")
        args += listOf("-c", "copy", "-f", "webm", output)
        return runFfmpeg(args, output)
    }

    /**
     * [path] 파일의 태그를 읽는다 (ffmpeg의 ffmetadata 덤프). 키는 모두 소문자.
     * 전체 태그에 없으면(opus · ogg는 첫 소리 스트림에 있다) 첫 소리 스트림의 태그로 채운다.
     */
    fun readTags(path: String): Map<String, String> {
        val tags = linkedMapOf<String, String>()
        for (extra in listOf(emptyList(), listOf("-map_metadata:g", "0:s:a:0"))) {
            val out = File("$path.meta.txt")
            try {
                val ok = try {
                    runFfmpeg(listOf("-nostdin", "-y", "-i", path, "-map_metadata", "0") + extra + listOf("-f", "ffmetadata", out.absolutePath), out.absolutePath)
                } catch (e: IllegalStateException) {
                    false
                }
                if (ok && out.exists()) {
                    for ((k, v) in readFfmetadata(out.absolutePath)) {
                        if (k.startsWith("[") || v.isEmpty()) continue
                        tags.putIfAbsent(k.lowercase(), v)
                    }
                }
            } finally {
                out.delete()
            }
            if (tags.containsKey("title") || tags.containsKey("artist")) break
        }
        return tags
    }

    private val knownKeys = setOf("title", "artist", "album", "genre", "lyrics")

    /** 앱이 넘긴 기본 칸(소문자)은 형식의 키 이름(대문자 또는 소문자)으로, 그 밖의 앱 전용 칸은 그대로. */
    private fun entriesOf(values: List<Pair<String, String>>, upper: Boolean): List<Pair<String, String>> =
        values.map { (key, value) ->
            val lower = key.lowercase()
            (if (lower in knownKeys) (if (upper) lower.uppercase() else lower) else key) to value
        }

    /** ffmetadata 텍스트. `=` `;` `#` `\` 와 줄바꿈은 앞에 `\`를 붙인다. */
    private fun ffmetadata(entries: List<Pair<String, String>>): String {
        val b = StringBuilder(";FFMETADATA1\n")
        for ((k, v) in entries) {
            b.append(k).append('=')
            for (c in v) {
                if (c == '=' || c == ';' || c == '#' || c == '\\' || c == '\n') b.append('\\')
                b.append(c)
            }
            b.append('\n')
        }
        return b.toString()
    }

    /** FLAC 그림 블록(앞면 커버, PNG): Vorbis `METADATA_BLOCK_PICTURE`의 값. 크기는 PNG 머리글에서 읽는다. */
    private fun pictureBlock(png: ByteArray): ByteArray {
        val width = ByteBuffer.wrap(png, 16, 4).int
        val height = ByteBuffer.wrap(png, 20, 4).int
        val mime = "image/png".toByteArray(Charsets.US_ASCII)
        val b = ByteBuffer.allocate(32 + mime.size + png.size)
        b.putInt(3).putInt(mime.size).put(mime).putInt(0)
        b.putInt(width).putInt(height).putInt(32).putInt(0).putInt(png.size).put(png)
        return b.array()
    }

    /** [args]로 ffmpeg를 돌려 [output]을 만든다. 실패하면 마지막 출력을 담아 예외를 던지고 [output]을 지운다. */
    private fun runFfmpeg(args: List<String>, output: String): Boolean {
        ensureInit()
        val ffmpeg = File(context.applicationInfo.nativeLibraryDir, "libffmpeg.so")
        if (!ffmpeg.exists()) return false
        val out = File(output)
        out.delete()
        val builder = ProcessBuilder(listOf(ffmpeg.absolutePath) + args)
        builder.environment()["LD_LIBRARY_PATH"] = libraryPath()
        builder.redirectErrorStream(true)
        val p = builder.start()
        process = p
        try {
            // 출력은 비우되 실패 원인을 알리려 마지막 부분만 남긴다.
            val tail = StringBuilder()
            p.inputStream.use { stream ->
                val buffer = ByteArray(8192)
                while (true) {
                    val n = stream.read(buffer)
                    if (n < 0) break
                    tail.append(String(buffer, 0, n, Charsets.UTF_8))
                    if (tail.length > 1200) tail.delete(0, tail.length - 800)
                }
            }
            val code = p.waitFor()
            if (code != 0) {
                out.delete()
                throw IllegalStateException("ffmpeg exit $code: ${tail.toString().trim().takeLast(400)}")
            }
            return true
        } finally {
            process = null
        }
    }

    /** ffmetadata 파일(`;FFMETADATA1`, `키=값`, `\`로 `=` `;` `#` `\` 줄바꿈을 이스케이프)을 (키, 값) 목록으로 읽는다. */
    private fun readFfmetadata(path: String): List<Pair<String, String>> {
        val text = File(path).readText(Charsets.UTF_8)
        val out = mutableListOf<Pair<String, String>>()
        val key = StringBuilder()
        val value = StringBuilder()
        var inValue = false
        var i = text.indexOf('\n') + 1 // 첫 줄(;FFMETADATA1)은 건너뛴다
        while (i < text.length) {
            val c = text[i]
            when {
                c == '\\' && i + 1 < text.length -> {
                    (if (inValue) value else key).append(text[i + 1])
                    i++
                }
                c == '=' && !inValue -> inValue = true
                c == '\n' -> {
                    if (key.isNotEmpty()) out += key.toString() to value.toString()
                    key.clear()
                    value.clear()
                    inValue = false
                }
                else -> (if (inValue) value else key).append(c)
            }
            i++
        }
        if (key.isNotEmpty()) out += key.toString() to value.toString()
        return out
    }

    /** ffmpeg 종료 코드가 0이면 true. */
    private fun convert(input: String, output: String, codec: String, bitrate: Int, format: String): Boolean {
        ensureInit()
        val ffmpeg = File(context.applicationInfo.nativeLibraryDir, "libffmpeg.so")
        if (!ffmpeg.exists()) return false
        val out = File(output)
        out.delete()
        val builder = ProcessBuilder(
            ffmpeg.absolutePath, "-nostdin", "-y", "-i", input,
            "-vn", "-map_metadata", "-1",
            "-c:a", codec, "-b:a", "${bitrate}k",
            "-f", format, output,
        )
        builder.environment()["LD_LIBRARY_PATH"] = libraryPath()
        builder.redirectErrorStream(true)
        val p = builder.start()
        process = p
        try {
            // 출력을 비우지 않으면 ffmpeg가 로그를 쓰다 멈춘다.
            p.inputStream.use { stream ->
                val buffer = ByteArray(8192)
                while (stream.read(buffer) >= 0) { /* 버린다 */ }
            }
            val code = p.waitFor()
            if (code != 0) out.delete()
            return code == 0
        } finally {
            process = null
        }
    }

    override fun dispose() {
        process?.destroy()
        super.dispose()
        io.shutdownNow()
    }

    companion object {
        const val NAME = "music_app/transcoder"
    }
}
