package com.mulo.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * 로컬 엔진(full 빌드): youtubedl-android가 APK에 넣어 둔 파이썬 · yt-dlp를 실행한다.
 * Android 10+는 내려받은 실행 파일을 돌릴 수 없어서 라이브러리 방식을 쓴다.
 * lite 빌드는 같은 이름의 빈 구현이 들어가 `available`이 false다.
 */
class YtDlpChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    // 초기화(파이썬 풀기)는 처음 한 번만 걸린다.
    @Volatile private var ready = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(true)
                "version" -> run(result) { mapOf("version" to YoutubeDL.version(context)) }
                "run" -> {
                    val url = call.argument<String>("url")
                    val options = call.argument<List<String>>("options") ?: emptyList()
                    if (url == null) {
                        result.error("bad_args", "url required", null)
                        return@setMethodCallHandler
                    }
                    run(result) { execute(url, options) }
                }
                "update" -> run(result) {
                    YoutubeDL.updateYoutubeDL(context, YoutubeDL.UpdateChannel.STABLE)
                    mapOf("version" to YoutubeDL.version(context))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensureInit() {
        if (ready) return
        synchronized(this) {
            if (ready) return
            YoutubeDL.getInstance().init(context)
            ready = true
        }
    }

    private fun execute(url: String, options: List<String>): Map<String, Any?> {
        val request = YoutubeDLRequest(url)
        options.forEach { request.addOption(it) }
        return try {
            val r = YoutubeDL.getInstance().execute(request)
            mapOf("exitCode" to r.exitCode, "stdout" to r.out, "stderr" to r.err)
        } catch (e: YoutubeDLException) {
            // yt-dlp가 0이 아닌 코드로 끝난 경우: 메시지에 stderr가 들어 있다.
            mapOf("exitCode" to 1, "stdout" to "", "stderr" to (e.message ?: ""))
        }
    }

    private fun run(result: MethodChannel.Result, block: () -> Map<String, Any?>) {
        io.execute {
            try {
                ensureInit()
                val value = block()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("ytdlp_failed", e.message, null) }
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    companion object {
        const val NAME = "music_app/ytdlp"
    }
}
