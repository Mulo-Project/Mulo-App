package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

/** lite 빌드: ffmpeg가 없다. `available`이 false라서 받은 원본 그대로 저장한다. */
class TranscoderChannel(@Suppress("UNUSED_PARAMETER") context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME) {
    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "available") result.success(false) else result.notImplemented()
        }
    }

    companion object {
        const val NAME = "music_app/transcoder"
    }
}
