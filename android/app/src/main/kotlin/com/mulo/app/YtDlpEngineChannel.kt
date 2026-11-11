package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * 로컬 엔진(yt-dlp) 호출 (`music_app/ytdlp_engine`). 실제 일은 [YtDlpEngine]이 하고 Dart는 결과만 받는다.
 *
 * Dart → 네이티브:
 * `search`(prefix · query · page · size → items · hasNext) · `searchPlaylists`(query · page · size → items · hasNext) ·
 * `info`(url → type=video/playlist …) · `channel`(url → thumbnail · subscriberCount) ·
 * `audio`(url · language? → url · headers) · `video`(url · maxHeight → url · headers · muxed) ·
 * `audioLanguages`(url → [id · name · isDefault]) · `subtitles`(url · prefer → language · automatic · cues, 없으면 null) ·
 * `saveVideo`(url · maxHeight · extension · dir · stem · id? → null, 진행률은 `progress`(id · progress)로 알린다).
 * 실패하면 오류 코드가 `unavailable` · `network` · `timeout` · `not_found` · `failed` 중 하나다.
 */
class YtDlpEngineChannel(context: Context, messenger: BinaryMessenger, runner: YtDlpRunner) :
    NativeChannel(messenger, NAME) {
    private val io: ExecutorService = Executors.newCachedThreadPool()
    private val engine = YtDlpEngine(runner, { File(context.cacheDir, "sub_${System.nanoTime()}") })

    init {
        channel.setMethodCallHandler { call, result ->
            fun str(key: String): String? = call.argument<String>(key)
            val url = str("url")
            when (call.method) {
                "available" -> result.success(engine.available)
                "search" -> {
                    val query = str("query") ?: return@setMethodCallHandler bad(result, "query")
                    val prefix = str("prefix") ?: "ytsearch"
                    val page = call.argument<Int>("page") ?: 0
                    val size = call.argument<Int>("size") ?: 20
                    runAsync(io, result, ERROR) { engine.search(prefix, query, page, size) }
                }
                "searchPlaylists" -> {
                    val query = str("query") ?: return@setMethodCallHandler bad(result, "query")
                    val page = call.argument<Int>("page") ?: 0
                    val size = call.argument<Int>("size") ?: 20
                    runAsync(io, result, ERROR) { engine.searchPlaylists(query, page, size) }
                }
                "info" -> {
                    if (url == null) return@setMethodCallHandler bad(result, "url")
                    runAsync(io, result, ERROR) { engine.info(url) }
                }
                "channel" -> {
                    if (url == null) return@setMethodCallHandler bad(result, "url")
                    runAsync(io, result, ERROR) { engine.channel(url) }
                }
                "audio" -> {
                    if (url == null) return@setMethodCallHandler bad(result, "url")
                    val language = str("language")
                    runAsync(io, result, ERROR) { engine.audio(url, language) }
                }
                "video" -> {
                    if (url == null) return@setMethodCallHandler bad(result, "url")
                    val height = call.argument<Int>("maxHeight") ?: 360
                    runAsync(io, result, ERROR) { engine.video(url, height) }
                }
                "audioLanguages" -> {
                    if (url == null) return@setMethodCallHandler bad(result, "url")
                    runAsync(io, result, ERROR) { engine.audioLanguages(url) }
                }
                "subtitles" -> {
                    if (url == null) return@setMethodCallHandler bad(result, "url")
                    val prefer = call.argument<List<String>>("prefer") ?: listOf("ko", "en")
                    runAsync(io, result, ERROR) { engine.subtitles(url, prefer) }
                }
                "saveVideo" -> {
                    val dir = str("dir")
                    val stem = str("stem")
                    val extension = str("extension")
                    if (url == null || dir == null || stem == null || extension == null) {
                        return@setMethodCallHandler bad(result, "url · dir · stem · extension")
                    }
                    val height = call.argument<Int>("maxHeight") ?: 1080
                    val id = str("id")
                    runAsync(io, result, ERROR) {
                        engine.saveVideo(url, height, extension, File(dir), stem) { p ->
                            if (id != null) notifyDart("progress", mapOf("id" to id, "progress" to p))
                        }
                        null
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun bad(result: io.flutter.plugin.common.MethodChannel.Result, what: String) =
        result.error("bad_args", "$what required", null)

    override fun dispose() {
        super.dispose()
        engine.dispose()
        io.shutdown()
    }

    companion object {
        const val NAME = "music_app/ytdlp_engine"
        private const val ERROR = "failed"
    }
}
