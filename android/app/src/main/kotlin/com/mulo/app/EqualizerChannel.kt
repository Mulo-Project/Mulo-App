package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** 이퀄라이저 통로. 약속은 docs/equalizer.md. 효과는 재생 엔진([PlaybackHub])의 오디오 세션에 붙는다. */
class EqualizerChannel(context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)

    init {
        PlaybackHub.init(context.applicationContext)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> result.success(EqualizerEngine.info())
                "apply" -> {
                    val levels = (call.argument<List<*>>("levels") ?: emptyList<Any>())
                        .map { (it as Number).toDouble() }
                    EqualizerEngine.apply(
                        call.argument<Boolean>("enabled") ?: false,
                        levels,
                        call.argument<Number>("bassBoost")?.toDouble() ?: 0.0,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val NAME = "music_app/equalizer"
    }
}
