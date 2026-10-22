package com.mulo.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.yausername.ffmpeg.FFmpeg
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * 오디오 변환(full 빌드): youtubedl-android의 ffmpeg 모듈이 APK에 넣어 둔 ffmpeg를 실행해
 * 받은 오디오를 mp3 · opus로 바꾼다. 라이브러리가 yt-dlp를 돌릴 때와 같은 방식으로
 * `nativeLibraryDir/libffmpeg.so`를 실행 파일로, 풀어 둔 공유 라이브러리를 `LD_LIBRARY_PATH`로 쓴다.
 * lite 빌드는 같은 이름의 빈 구현이 들어가 `available`이 false다.
 */
class TranscoderChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

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
                    io.execute {
                        try {
                            val ok = convert(input, output, codec, bitrate, format)
                            main.post { result.success(ok) }
                        } catch (e: Exception) {
                            main.post { result.error("convert_failed", e.message, null) }
                        }
                    }
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
                    io.execute {
                        try {
                            val ok = tag(input, meta, output, format, call.argument<String>("cover"))
                            main.post { result.success(ok) }
                        } catch (e: Exception) {
                            main.post { result.error("tag_failed", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensureInit() {
        if (ready) return
        synchronized(this) {
            if (ready) return
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
        val libs = File(context.noBackupFilesDir, "youtubedl-android/packages/ffmpeg/usr/lib")
        val out = File(output)
        out.delete()
        val args = mutableListOf(ffmpeg.absolutePath, "-nostdin", "-y", "-i", input, "-i", meta)
        if (cover != null) args += listOf("-i", cover)
        args += listOf("-map", "0:a")
        // mp3 커버는 그림 입력을 첨부 그림(attached_pic)으로 붙인다.
        if (cover != null) args += listOf("-map", "2:v", "-disposition:v:0", "attached_pic")
        args += listOf("-map_metadata", "1", "-map_metadata:s:a:0", "1:g", "-c", "copy")
        // 다른 플레이어에서도 열리도록 ID3는 v2.3으로 쓴다.
        if (format == "mp3") args += listOf("-id3v2_version", "3")
        args += listOf("-f", format, output)
        val builder = ProcessBuilder(args)
        builder.environment()["LD_LIBRARY_PATH"] =
            libs.absolutePath + (System.getenv("LD_LIBRARY_PATH")?.let { ":$it" } ?: "")
        builder.redirectErrorStream(true)
        val p = builder.start()
        process = p
        try {
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

    /** ffmpeg 종료 코드가 0이면 true. */
    private fun convert(input: String, output: String, codec: String, bitrate: Int, format: String): Boolean {
        ensureInit()
        val ffmpeg = File(context.applicationInfo.nativeLibraryDir, "libffmpeg.so")
        if (!ffmpeg.exists()) return false
        val libs = File(context.noBackupFilesDir, "youtubedl-android/packages/ffmpeg/usr/lib")
        val out = File(output)
        out.delete()
        val builder = ProcessBuilder(
            ffmpeg.absolutePath, "-nostdin", "-y", "-i", input,
            "-vn", "-map_metadata", "-1",
            "-c:a", codec, "-b:a", "${bitrate}k",
            "-f", format, output,
        )
        builder.environment()["LD_LIBRARY_PATH"] =
            libs.absolutePath + (System.getenv("LD_LIBRARY_PATH")?.let { ":$it" } ?: "")
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

    fun dispose() {
        process?.destroy()
        channel.setMethodCallHandler(null)
        io.shutdownNow()
    }

    companion object {
        const val NAME = "music_app/transcoder"
    }
}
