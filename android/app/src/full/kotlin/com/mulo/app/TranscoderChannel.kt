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
                    runAsync(io, result, "tag_failed") { tag(input, meta, output, format, call.argument<String>("cover")) }
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

    /**
     * 소리는 그대로(`-c copy`) 두고 ffmetadata 파일의 태그만 새로 써서 [output]에 만든다.
     * 전체 태그와 첫 오디오 스트림 태그 둘 다에 넣어, ogg 쓰기가 어느 쪽을 읽어도 같다.
     */
    private fun tag(input: String, meta: String, output: String, format: String, cover: String?): Boolean {
        ensureInit()
        val ffmpeg = File(context.applicationInfo.nativeLibraryDir, "libffmpeg.so")
        if (!ffmpeg.exists()) return false
        val out = File(output)
        out.delete()
        val args = mutableListOf(ffmpeg.absolutePath, "-nostdin", "-y", "-i", input, "-i", meta)
        if (cover != null) args += listOf("-i", cover)
        args += listOf("-map", "0:a")
        // mp3 커버는 그림 입력을 첨부 그림(attached_pic)으로 붙인다.
        // 그림 종류를 "앞면 커버"로 적어 다른 플레이어도 커버로 읽게 한다 (안 적으면 "기타" 그림이 된다).
        if (cover != null) {
            args += listOf(
                "-map", "2:v", "-disposition:v:0", "attached_pic",
                "-metadata:s:v", "title=Album cover", "-metadata:s:v", "comment=Cover (front)",
            )
        }
        args += listOf("-map_metadata", "1", "-map_metadata:s:a:0", "1:g", "-c", "copy")
        // 다른 플레이어에서도 열리도록 ID3는 v2.3으로 쓴다.
        if (format == "mp3") args += listOf("-id3v2_version", "3")
        args += listOf("-f", format, output)
        val builder = ProcessBuilder(args)
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
