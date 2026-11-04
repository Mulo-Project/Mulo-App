package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** 앱(Dart)과 [PlaybackHub]를 잇는 통로. 약속은 docs/native-playback.md. */
class PlaybackChannel(context: Context, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, "music_app/playback")
    private val events = EventChannel(messenger, "music_app/playback/events")

    init {
        PlaybackHub.init(context.applicationContext)
        methods.setMethodCallHandler { call, result ->
            try {
                handle(call, result)
            } catch (e: Exception) {
                MuloLog.e(MuloLog.PLAYBACK, "${call.method} 실패: ${e.message}", e)
                result.error("native_error", e.message, null)
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) = PlaybackHub.setSink(sink)
            override fun onCancel(arguments: Any?) = PlaybackHub.setSink(null)
        })
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setQueue" -> PlaybackHub.setQueue(call.arguments as Map<*, *>, result)
            "setQueueArt" -> { PlaybackHub.setQueueArt(call.arguments as Map<*, *>); result.success(null) }
            "playNext" -> { PlaybackHub.playNext(call.arguments as Map<*, *>); result.success(PlaybackHub.queueState()) }
            "addToQueue" -> { PlaybackHub.addToQueue(call.arguments as Map<*, *>); result.success(PlaybackHub.queueState()) }
            "removeFromQueue" -> { PlaybackHub.removeFromQueue(call.arguments as String); result.success(PlaybackHub.queueState()) }
            "moveInQueue" -> {
                val args = call.arguments as Map<*, *>
                PlaybackHub.moveInQueue((args["from"] as Number).toInt(), (args["to"] as Number).toInt())
                result.success(PlaybackHub.queueState())
            }
            "setShuffle" -> { PlaybackHub.setShuffle(call.arguments as? Boolean ?: false); result.success(PlaybackHub.queueState()) }
            "setRepeat" -> { PlaybackHub.setRepeat(call.arguments as? String); result.success(PlaybackHub.queueState()) }
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
            "setLoop" -> {
                val args = call.arguments as Map<*, *>
                PlaybackHub.setLoop((args["startMs"] as? Number)?.toLong(), (args["endMs"] as? Number)?.toLong())
                result.success(null)
            }
            "setSession" -> { PlaybackHub.setSession(call.arguments as? Map<*, *>); result.success(null) }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        PlaybackHub.setSink(null)
    }
}
