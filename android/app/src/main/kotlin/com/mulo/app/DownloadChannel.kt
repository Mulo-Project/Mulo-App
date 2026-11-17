package com.mulo.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject

/**
 * 받기 큐 채널 (`music_app/downloads`). 실제 일은 [DownloadEngine]이 하고 Dart는 요청을 넘기고 상태만 받는다.
 *
 * Dart → 네이티브: `enqueue`(request JSON 글 → id) · `pause` · `resume` · `retry` · `cancel`(id) · `cancelAll`(playlistId? → 뺀 곡 수) ·
 * `snapshot`(→ 대기열 목록) · `findExisting`(url → trackId? · inQueue) · `sourceUrlOf`(trackId → url?) ·
 * `configure`(알림 글 · 설정 JSON 글) · `setPreviewing`(id?) · `dbReady`(Dart가 이벤트를 받을 준비가 됐다: 옛 Dart 큐 기록 이전 · 못 넘긴 등록 다시 넘김) · `ack`(trackId: Dart가 보관함에 등록했다).
 * 네이티브 → Dart (EventChannel `music_app/downloads/events`, {event, data}): `queue`(목록, 듣기 시작할 때 먼저 한 번) · `tagNotice`(title · extension · ok · detail) · `saved`(폴더) · `engineError`(글) · `registered`(보관함에 넣을 곡 값: Dart가 drift에 쓰고 `ack`).
 */
class DownloadChannel(
    context: Context,
    messenger: BinaryMessenger,
    ytdlp: YtDlpEngine,
    transcoder: TranscoderChannel,
    store: MediaStoreChannel,
    tags: TagChannel,
) : NativeChannel(messenger, NAME) {
    /** 네이티브 → Dart 상태 흐름 (`music_app/downloads/events`). 듣는 쪽이 없으면(앱이 꺼져 있으면) 보내지 않는다. */
    private val events = EventChannel(messenger, EVENTS)
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: EventChannel.EventSink? = null

    val engine = DownloadEngine(context, ytdlp, transcoder, store, tags) { event, data ->
        main.post {
            val s = sink
            if (s == null) {
                // 듣는 쪽(Dart)이 없다: 상태는 Dart가 듣기 시작할 때 다시 받는다.
                if (event != "queue") MuloLog.d(MuloLog.NATIVE, "받기 이벤트를 받을 화면이 없음: $event")
            } else {
                s.success(mapOf("event" to event, "data" to data))
            }
        }
    }

    init {
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, s: EventChannel.EventSink) {
                sink = s
                // 듣기 시작하면 지금 대기열부터 보낸다 (그 전에 바뀐 것을 놓치지 않게).
                s.success(mapOf("event" to "queue", "data" to engine.snapshot()))
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
        channel.setMethodCallHandler { call, result ->
            fun id(): String? = call.argument<String>("id")
            try {
                when (call.method) {
                    "enqueue" -> result.success(engine.enqueue(JSONObject(call.argument<String>("request") ?: "{}")))
                    "pause" -> { id()?.let(engine::pause); result.success(null) }
                    "resume" -> { id()?.let(engine::resume); result.success(null) }
                    "retry" -> { id()?.let(engine::retry); result.success(null) }
                    "cancel" -> { id()?.let(engine::cancel); result.success(null) }
                    "cancelAll" -> result.success(engine.cancelAll(call.argument<String>("playlistId")))
                    "snapshot" -> result.success(engine.snapshot())
                    "findExisting" -> result.success(engine.findExisting(call.argument<String>("url") ?: ""))
                    "sourceUrlOf" -> result.success(engine.sourceUrlOf(call.argument<String>("trackId") ?: ""))
                    "configure" -> { engine.configure(JSONObject(call.argument<String>("config") ?: "{}")); result.success(null) }
                    "setPreviewing" -> { engine.previewingId = call.argument<String>("id"); result.success(null) }
                    "dbReady" -> { engine.dbReady(); result.success(null) }
                    "ack" -> { call.argument<String>("trackId")?.let(engine::ack); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("failed", e.message, null)
            }
        }
    }

    override fun dispose() {
        events.setStreamHandler(null)
        sink = null
        engine.dispose()
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/downloads"
        const val EVENTS = "music_app/downloads/events"
    }
}
