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
 * 같은 채널로 검색 · 재생목록 곡 목록도 읽는다 ([YoutubeBrowser]):
 * `search`(query · page · size → items · hasNext) · `playlist`(playlistId → title · items) ·
 * `searchPlaylists`(query · page · size → items · hasNext) · `searchChannels`(query → items) ·
 * `channelDetails`(channelId → bannerUrl · logoUrl · subscriberCount · description) ·
 * `resolveChannelId`(url → id?) · `channelFeed`(channelId → 최근 영상들, [YoutubeChannels]).
 * 곡 항목은 id · title · uploader · seconds? · thumbnail? · channelId? · views? · isLive · description.
 * 실패하면 `resolve_failed` 오류에 까닭을 담는다.
 */
class YoutubeResolveChannel(@Suppress("UNUSED_PARAMETER") context: Context, messenger: BinaryMessenger) :
    NativeChannel(messenger, NAME) {
    private val io: ExecutorService = Executors.newCachedThreadPool()

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "warmUp" -> {
                    runAsync(io, result, ERROR) { YoutubeBrowser.warmUp(); null }
                    return@setMethodCallHandler
                }
                "searchPlaylists" -> {
                    val query = call.argument<String>("query")
                    if (query == null) {
                        result.error("bad_args", "query required", null)
                        return@setMethodCallHandler
                    }
                    val page = call.argument<Int>("page") ?: 0
                    val size = call.argument<Int>("size") ?: 20
                    runAsync(io, result, ERROR) { YoutubeBrowser.searchPlaylists(query, page, size) }
                    return@setMethodCallHandler
                }
                "searchChannels" -> {
                    val query = call.argument<String>("query")
                    if (query == null) {
                        result.error("bad_args", "query required", null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, ERROR) { YoutubeBrowser.searchChannels(query) }
                    return@setMethodCallHandler
                }
                "channelDetails" -> {
                    val channelId = call.argument<String>("channelId")
                    if (channelId == null) {
                        result.error("bad_args", "channelId required", null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, ERROR) { YoutubeChannels.details(channelId) }
                    return@setMethodCallHandler
                }
                "resolveChannelId" -> {
                    val url = call.argument<String>("url")
                    if (url == null) {
                        result.error("bad_args", "url required", null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, ERROR) { YoutubeChannels.resolveChannelId(url) }
                    return@setMethodCallHandler
                }
                "channelFeed" -> {
                    val channelId = call.argument<String>("channelId")
                    if (channelId == null) {
                        result.error("bad_args", "channelId required", null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, ERROR) { YoutubeChannels.feed(channelId) }
                    return@setMethodCallHandler
                }
                "search" -> {
                    val query = call.argument<String>("query")
                    if (query == null) {
                        result.error("bad_args", "query required", null)
                        return@setMethodCallHandler
                    }
                    val page = call.argument<Int>("page") ?: 0
                    val size = call.argument<Int>("size") ?: 20
                    runAsync(io, result, ERROR) { YoutubeBrowser.search(query, page, size) }
                    return@setMethodCallHandler
                }
                "playlist" -> {
                    val listId = call.argument<String>("playlistId")
                    if (listId == null) {
                        result.error("bad_args", "playlistId required", null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, ERROR) { YoutubeBrowser.playlist(listId) }
                    return@setMethodCallHandler
                }
            }
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
