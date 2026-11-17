package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import org.json.JSONObject

/**
 * 받기 큐 채널 (`music_app/downloads`). 실제 일은 [DownloadEngine]이 하고 Dart는 요청을 넘기고 상태만 받는다.
 *
 * Dart → 네이티브: `enqueue`(request JSON 글 → id) · `pause` · `resume` · `retry` · `cancel`(id) · `cancelAll`(playlistId? → 뺀 곡 수) ·
 * `snapshot`(→ 대기열 목록) · `findExisting`(url → trackId? · inQueue) · `sourceUrlOf`(trackId → url?) ·
 * `configure`(알림 글 · 설정 JSON 글) · `setPreviewing`(id?) · `dbReady`(앱이 DB를 열었다) · `importLegacy`(queue? · sources?).
 * 네이티브 → Dart: `queue`(목록) · `tagNotice`(title · extension · ok · detail) · `saved`(폴더) · `engineError`(글) · `libraryChanged`.
 */
class DownloadChannel(
    context: Context,
    messenger: BinaryMessenger,
    ytdlp: YtDlpEngine,
    transcoder: TranscoderChannel,
    store: MediaStoreChannel,
    tags: TagChannel,
) : NativeChannel(messenger, NAME) {
    val engine = DownloadEngine(context, ytdlp, transcoder, store, tags) { method, args -> notifyDart(method, args) }

    init {
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
                    "importLegacy" -> {
                        engine.importLegacy(call.argument<String>("queue"), call.argument<String>("sources"))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("failed", e.message, null)
            }
        }
    }

    override fun dispose() {
        engine.dispose()
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/downloads"
    }
}
