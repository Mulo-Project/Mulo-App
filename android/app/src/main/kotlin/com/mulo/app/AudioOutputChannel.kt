package com.mulo.app

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger

/** 지금 소리가 나가는 출력 기기를 알려 주고, 기기가 바뀌면(연결 · 끊김) 앱(Dart)에 `changed`로 알린다. */
class AudioOutputChannel(private val context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME) {
    private val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private val callback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) = notifyChanged()
        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) = notifyChanged()
    }

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "current") result.success(AudioOutputs.current(context)) else result.notImplemented()
        }
        audio.registerAudioDeviceCallback(callback, Handler(Looper.getMainLooper()))
    }

    private fun notifyChanged() {
        channel.invokeMethod("changed", AudioOutputs.current(context))
    }

    override fun dispose() {
        audio.unregisterAudioDeviceCallback(callback)
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/audio_output"
    }
}
