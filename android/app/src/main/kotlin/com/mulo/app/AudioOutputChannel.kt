package com.mulo.app

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** 지금 소리가 나가는 출력 기기(블루투스 · 유선 · USB · 스피커)를 알려 준다. */
class AudioOutputChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "current") result.success(current()) else result.notImplemented()
        }
    }

    private fun current(): Map<String, String> {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = audio.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        // 우선순위: 블루투스 > 유선 > USB > 내장 스피커.
        fun pick(vararg types: Int) = devices.firstOrNull { it.type in types }
        val bt = pick(AudioDeviceInfo.TYPE_BLUETOOTH_A2DP, AudioDeviceInfo.TYPE_BLUETOOTH_SCO, AudioDeviceInfo.TYPE_BLE_HEADSET, AudioDeviceInfo.TYPE_BLE_SPEAKER)
        val wired = pick(AudioDeviceInfo.TYPE_WIRED_HEADPHONES, AudioDeviceInfo.TYPE_WIRED_HEADSET)
        val usb = pick(AudioDeviceInfo.TYPE_USB_DEVICE, AudioDeviceInfo.TYPE_USB_HEADSET)
        val (type, info) = when {
            bt != null -> "bluetooth" to bt
            wired != null -> "wired" to wired
            usb != null -> "usb" to usb
            else -> "speaker" to pick(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER)
        }
        val name = if (type == "speaker") "" else info?.productName?.toString() ?: ""
        return mapOf("type" to type, "name" to name)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val NAME = "music_app/audio_output"
    }
}
