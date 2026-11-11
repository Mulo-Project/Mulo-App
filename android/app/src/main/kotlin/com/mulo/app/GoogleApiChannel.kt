package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * 구글 YouTube Data API 읽기 (`music_app/google_api`). 읽기 · 쪽 넘기기 · 오류 가르기는 [GoogleApi]가 네이티브에서 하고,
 * Dart는 로그인으로 얻은 토큰을 넘겨 결과만 받는다.
 *
 * Dart → 네이티브: `list`(token · kind(`playlists` · `subscriptions`) · query · maxPages · progressId? → 항목들).
 * 네이티브 → Dart: `progress`(id · loaded) — 쪽을 읽을 때마다 지금까지 읽은 수.
 * 실패는 오류 코드 `unauthorized` · `no_channel` · `network` · `timeout` · `failed`.
 */
class GoogleApiChannel(@Suppress("UNUSED_PARAMETER") context: Context, messenger: BinaryMessenger) :
    NativeChannel(messenger, NAME) {
    private val io: ExecutorService = Executors.newCachedThreadPool()

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "list" -> {
                    val token = call.argument<String>("token")
                    val kind = call.argument<String>("kind")
                    if (token == null || kind == null) {
                        result.error("bad_args", "token · kind required", null)
                        return@setMethodCallHandler
                    }
                    val query = call.argument<Map<String, String>>("query") ?: emptyMap()
                    val maxPages = call.argument<Int>("maxPages") ?: 6
                    val progressId = call.argument<Int>("progressId")
                    runAsync(io, result, "failed") {
                        GoogleApi.list(token, kind, query, maxPages) { loaded ->
                            if (progressId != null) notifyDart("progress", mapOf("id" to progressId, "loaded" to loaded))
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispose() {
        io.shutdown()
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/google_api"
    }
}
