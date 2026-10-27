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
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "setQueue" -> PlaybackHub.setQueue(call.arguments as Map<*, *>, result)
                "setQueueArt" -> { PlaybackHub.setQueueArt(call.arguments as Map<*, *>); result.success(null) }
                "skipTo" -> { PlaybackHub.skipTo((call.arguments as Number).toInt()); result.success(null) }
                "getState" -> result.success(PlaybackHub.getState())
                "takeOpenPlayerRequest" -> result.success(PlaybackHub.takeOpenPlayerRequest())
                "play" -> { PlaybackHub.play(); result.success(null) }
                "pause" -> { PlaybackHub.pause(); result.success(null) }
                "seek" -> { PlaybackHub.seek((call.arguments as Number).toLong()); result.success(null) }
                "setOutputBehavior" -> {
                    val args = call.arguments as Map<*, *>
                    PlaybackHub.setOutputBehavior(args["pauseOnDisconnect"] as? Boolean ?: true, args["resumeOnConnect"] as? Boolean ?: false)
                    PlaybackHub.setResumeWithoutNotification(args["resumeWithoutNotification"] as? Boolean ?: true)
                    result.success(null)
                }
                "setMixWithOthers" -> { PlaybackHub.setMixWithOthers(call.arguments as? Boolean ?: false); result.success(null) }
                "setSpeed" -> { PlaybackHub.setSpeed((call.arguments as? Number)?.toDouble() ?: 1.0); result.success(null) }
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
