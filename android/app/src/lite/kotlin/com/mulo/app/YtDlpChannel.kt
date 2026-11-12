package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

/** lite 빌드: 로컬 엔진이 없다. `available`이 false라서 서버 모드만 쓴다. */
class YtDlpChannel(@Suppress("UNUSED_PARAMETER") context: Context, messenger: BinaryMessenger) :
    NativeChannel(messenger, NAME),
    YtDlpRunner {
    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "available") result.success(false) else result.notImplemented()
        }
    }

    override val available: Boolean get() = false

    override fun run(args: List<String>, id: String, onProgress: ((Double) -> Unit)?): YtDlpRun =
        throw YtDlpException("unavailable", "yt-dlp")

    override fun cancel(id: String): Boolean = false

    companion object {
        const val NAME = "music_app/ytdlp"
    }
}
