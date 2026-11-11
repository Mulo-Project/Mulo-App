package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * 유튜브 재생 주소 읽기 (`music_app/youtube_resolve`). 읽는 일은 [YoutubeResolver]가 네이티브에서 하고 Dart는 결과만 받는다.
 *
 * Dart → 네이티브: `audio`(videoId · language? · preferWebm → url · headers · fallbacks, 없으면 null) ·
 * `video`(videoId · maxHeight → url · headers · muxed, 없으면 null) · `languages`(videoId → [id · name · isDefault]).
 * 실패하면 `resolve_failed` 오류에 까닭을 담는다.
 */
class YoutubeResolveChannel(@Suppress("UNUSED_PARAMETER") context: Context, messenger: BinaryMessenger) :
    NativeChannel(messenger, NAME) {
    private val io: ExecutorService = Executors.newCachedThreadPool()

    init {
        channel.setMethodCallHandler { call, result ->
            val id = call.argument<String>("videoId")
            if (id == null) {
                result.error("bad_args", "videoId required", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "audio" -> {
                    val language = call.argument<String>("language")
                    val webm = call.argument<Boolean>("preferWebm") ?: true
                    runAsync(io, result, ERROR) { YoutubeResolver.audio(id, language, webm) }
                }
                "video" -> {
                    val height = call.argument<Int>("maxHeight") ?: 360
                    runAsync(io, result, ERROR) { YoutubeResolver.video(id, height) }
                }
                "languages" -> runAsync(io, result, ERROR) { YoutubeResolver.languages(id) }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispose() {
        io.shutdown()
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/youtube_resolve"
        private const val ERROR = "resolve_failed"
    }
}
