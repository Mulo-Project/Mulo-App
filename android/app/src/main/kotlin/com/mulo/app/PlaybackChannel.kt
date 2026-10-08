package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** 앱(Dart)과 [PlaybackHub]를 잇는 통로. 약속은 docs/native-playback.md. */
class PlaybackChannel(context: Context, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, "music_app/playback")
    private val events = EventChannel(messenger, "music_app/playback/events")

    init {
        PlaybackHub.init(context.applicationContext)
        // 앱 화면이 새로 시작되면 Dart의 대기열은 비어 있다: 옛 알림 · 소리를 남기지 않는다.
        PlaybackHub.reset()
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "load" -> PlaybackHub.load(call.arguments as String, result)
                "play" -> { PlaybackHub.play(); result.success(null) }
                "pause" -> { PlaybackHub.pause(); result.success(null) }
                "seek" -> { PlaybackHub.seek((call.arguments as Number).toLong()); result.success(null) }
                "setSession" -> { PlaybackHub.setSession(call.arguments as? Map<*, *>); result.success(null) }
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) = PlaybackHub.setSink(sink)
            override fun onCancel(arguments: Any?) = PlaybackHub.setSink(null)
        })
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        PlaybackHub.setSink(null)
    }
}
