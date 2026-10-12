package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** 이퀄라이저 통로. 약속은 docs/equalizer.md. 효과는 재생 엔진([PlaybackHub])의 오디오 세션에 붙는다. */
class EqualizerChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)

    init {
        PlaybackHub.init(context.applicationContext)
        EqualizerProfiles.onDeviceChanged = { channel.invokeMethod("deviceChanged", EqualizerProfiles.currentDevice(context)) }
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
                        call.argument<Number>("virtualizer")?.toDouble() ?: 0.0,
                        call.argument<Number>("reverb")?.toInt() ?: 0,
                        call.argument<Boolean>("limiter") ?: true,
                    )
                    result.success(null)
                }
                // 지금 출력 기기와 그 기기 전용 값이 있는지.
                "device" -> result.success(EqualizerProfiles.currentDevice(context))
                "profile" -> result.success(EqualizerProfiles.currentProfile(context))
                "saveProfile" -> { EqualizerProfiles.saveProfile(context, call.arguments as Map<*, *>); result.success(null) }
                "deleteProfile" -> { EqualizerProfiles.deleteProfile(context); result.success(null) }
                "setBase" -> { EqualizerProfiles.setBase(context, call.arguments as Map<*, *>); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        EqualizerProfiles.onDeviceChanged = null
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val NAME = "music_app/equalizer"
    }
}
