package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

/** 이퀄라이저 통로. 약속은 docs/equalizer.md. 효과는 재생 엔진([PlaybackHub])의 오디오 세션에 붙는다. */
class EqualizerChannel(private val context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME) {

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
                "profileFor" -> result.success(EqualizerProfiles.profileFor(context, call.arguments as String))
                "saveProfileFor" -> {
                    EqualizerProfiles.saveProfileFor(context, call.argument<String>("key") ?: "", call.argument<Map<String, Any?>>("values") ?: emptyMap<String, Any?>())
                    result.success(null)
                }
                "presets" -> result.success(EqualizerProfiles.presets(context))
                "savePreset" -> { EqualizerProfiles.savePreset(context, call.arguments as Map<*, *>); result.success(null) }
                "deletePreset" -> { EqualizerProfiles.deletePreset(context, call.arguments as String); result.success(null) }
                "devices" -> result.success(EqualizerProfiles.devices(context))
                "assignPreset" -> {
                    EqualizerProfiles.assignPreset(context, call.argument<String>("key") ?: "", call.argument<String>("presetId"))
                    result.success(null)
                }
                "setBase" -> { EqualizerProfiles.setBase(context, call.arguments as Map<*, *>); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispose() {
        EqualizerProfiles.onDeviceChanged = null
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/equalizer"
    }
}
