package com.mulo.app

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import java.io.File
import java.util.concurrent.Executors

/**
 * 가사: 음원 태그 속 가사를 읽으려면 파일 경로가 필요한데 MediaStore 곡은 content:// 주소뿐이라,
 * 곡을 캐시 폴더로 복사해 경로를 돌려준다. 읽은 뒤 Flutter가 바로 지운다.
 */
class LyricsChannel(private val context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME) {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "copyToCache" -> {
                    val uri = call.arguments as? String
                    if (uri == null) {
                        result.error("bad_args", "uri required", null)
                        return@setMethodCallHandler
                    }
                    io.execute {
                        try {
                            val path = copyToCache(Uri.parse(uri))
                            main.post { result.success(path) }
                        } catch (e: Exception) {
                            main.post { result.error("copy_failed", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun copyToCache(uri: Uri): String? {
        val dir = File(context.cacheDir, "lyrics_probe").apply { mkdirs() }
        val out = File(dir, "probe_${System.nanoTime()}")
        val input = context.contentResolver.openInputStream(uri) ?: return null
        input.use { i -> out.outputStream().use { o -> i.copyTo(o) } }
        return out.absolutePath
    }

    override fun dispose() {
        super.dispose()
        io.shutdown()
    }

    companion object {
        const val NAME = "music_app/lyrics"
    }
}
