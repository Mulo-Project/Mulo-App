package com.mulo.app

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager

/** 소리가 나가는 출력 기기(블루투스 · 유선 · USB · 스피커)를 읽는 도구. */
object AudioOutputs {
    private val BLUETOOTH = intArrayOf(
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
        AudioDeviceInfo.TYPE_BLE_HEADSET,
        AudioDeviceInfo.TYPE_BLE_SPEAKER,
    )
    private val WIRED = intArrayOf(AudioDeviceInfo.TYPE_WIRED_HEADPHONES, AudioDeviceInfo.TYPE_WIRED_HEADSET)
    private val USB = intArrayOf(AudioDeviceInfo.TYPE_USB_DEVICE, AudioDeviceInfo.TYPE_USB_HEADSET)

    /** 기기 종류 (`bluetooth` `wired` `usb`). 내장 스피커 등 그 밖의 기기는 null. */
    fun kindOf(device: AudioDeviceInfo): String? = when {
        !device.isSink -> null
        device.type in BLUETOOTH -> "bluetooth"
        device.type in WIRED -> "wired"
        device.type in USB -> "usb"
        else -> null
    }

    /** 연결되면 "이어폰을 꽂았다"고 볼 기기인지 (내장 스피커 · 통화용 기기는 제외). */
    fun isHeadset(device: AudioDeviceInfo): Boolean =
        device.isSink && (device.type in BLUETOOTH || device.type in WIRED || device.type in USB)

    /** `{type: speaker|wired|bluetooth|usb, name}`. 우선순위는 블루투스 > 유선 > USB > 내장 스피커. */
    fun current(context: Context): Map<String, String> {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = audio.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        fun pick(types: IntArray) = devices.firstOrNull { it.type in types }
        val bt = pick(BLUETOOTH)
        val wired = pick(WIRED)
        val usb = pick(USB)
        val (type, info) = when {
            bt != null -> "bluetooth" to bt
            wired != null -> "wired" to wired
            usb != null -> "usb" to usb
            else -> "speaker" to pick(intArrayOf(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER))
        }
        val name = if (type == "speaker") "" else info?.productName?.toString() ?: ""
        return mapOf("type" to type, "name" to name)
    }
}
