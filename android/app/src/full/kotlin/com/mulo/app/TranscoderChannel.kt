package com.mulo.app

import android.content.Context
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import io.flutter.plugin.common.BinaryMessenger
import java.io.File
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
                "tag" -> {
                    val input = call.argument<String>("input")
                    val meta = call.argument<String>("meta")
                    val output = call.argument<String>("output")
                    val format = call.argument<String>("format")
                    if (input == null || meta == null || output == null || format == null) {
                        result.error("bad_args", "input, meta, output, format required", null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, "tag_failed") {
                        if (format == "mp3") tagMp3(input, meta, output, call.argument<String>("cover"))
                        else tagOgg(input, meta, output)
                    }
                }
                "tagVideo" -> {
                    val input = call.argument<String>("input")
                    val meta = call.argument<String>("meta")
                    val output = call.argument<String>("output")
                    val format = call.argument<String>("format")
                    if (input == null || meta == null || output == null || format == null) {
                        result.error("bad_args", "input, meta, output, format required", null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, "tag_failed") {
                        if (format == "mp4") tagMp4(input, meta, output, call.argument<String>("cover"))
                        else tagWebm(input, meta, output)
                    }
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

    // 태그 쓰기: 형식마다 자기 함수가 자기 ffmpeg 인자를 만든다 (한 형식의 변경이 다른 형식에 새지 않게).
    // 공통인 것은 ffmpeg를 돌리는 부분([runFfmpeg])과 태그 값을 `-metadata`로 바꾸는 부분([metadataArgs])뿐이다.
    // 모두 소리 · 영상은 그대로(`-c copy`) 두고, 파일에 있던 태그는 두고 넘어온 칸만 덮어쓴다 (빈 값은 그 칸을 지운다).

    /**
     * mp3: 그림이 있으면 첨부 그림(attached_pic)으로 붙이고, 없으면 파일에 있던 커버 그림을 그대로 둔다.
     * 그림 종류를 "앞면 커버"로 적어 다른 플레이어도 커버로 읽게 하고, ID3는 v2.3으로 써서 다른 플레이어에서도 열리게 한다.
     */
    private fun tagMp3(input: String, meta: String, output: String, cover: String?): Boolean {
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
        args += metadataArgs(meta)
        args += listOf("-c", "copy", "-id3v2_version", "3", "-f", "mp3", output)
        return runFfmpeg(args, output)
    }

    /**
     * opus · ogg: 소리 스트림만 넘긴다 (커버는 태그 값 METADATA_BLOCK_PICTURE로 meta에 들어 있다).
     * 태그는 전체와 첫 소리 스트림 둘 다에 넣어, ogg 쓰기가 어느 쪽을 읽어도 같다.
     */
    private fun tagOgg(input: String, meta: String, output: String): Boolean {
        val args = mutableListOf("-nostdin", "-y", "-i", input, "-map", "0:a")
        for ((key, value) in readFfmetadata(meta)) {
            args += listOf("-metadata", "$key=$value", "-metadata:s:a:0", "$key=$value")
        }
        args += listOf("-c", "copy", "-f", "ogg", output)
        return runFfmpeg(args, output)
    }

    /** mp4 영상: 전체 스트림을 넘기고, 그림이 있으면 첨부 그림으로 더한다. genre 등 title · artist 밖의 칸도 쓰도록 한다. */
    private fun tagMp4(input: String, meta: String, output: String, cover: String?): Boolean {
        val args = mutableListOf("-nostdin", "-y", "-i", input)
        if (cover != null) args += listOf("-i", cover)
        args += listOf("-map", "0")
        if (cover != null) args += listOf("-map", "1:v", "-disposition:v:1", "attached_pic")
        args += metadataArgs(meta)
        args += listOf("-c", "copy", "-movflags", "+use_metadata_tags", "-f", "mp4", output)
        return runFfmpeg(args, output)
    }

    /** webm(Matroska) 영상: 첨부 그림을 쓰지 않아 글 태그만 쓴다. */
    private fun tagWebm(input: String, meta: String, output: String): Boolean {
        val args = mutableListOf("-nostdin", "-y", "-i", input, "-map", "0")
        args += metadataArgs(meta)
        args += listOf("-c", "copy", "-f", "webm", output)
        return runFfmpeg(args, output)
    }

    /** ffmetadata 파일의 칸들을 전체 태그용 `-metadata 키=값` 인자로. */
    private fun metadataArgs(meta: String): List<String> =
        readFfmetadata(meta).flatMap { (key, value) -> listOf("-metadata", "$key=$value") }

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
