package com.mulo.app

import android.content.Context
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * 곡 파일의 태그 읽기 · 쓰기 (`music_app/tags`). Dart는 형식을 모르는 값(제목 · 아티스트 · 앨범 · 장르 · 가사 · 앱 전용 칸 ·
 * 커버 이미지 경로 · 확대 · 위치 · 각도)과 파일 하나(`content://` 주소 또는 경로)만 넘기고, 형식 구분 · 복사 · 태그 쓰기 · 덮어쓰기 · 동의 창은 여기서 한다.
 * 형식마다 다른 규칙은 [TagFormats]가 고른 형식의 함수([TranscoderChannel])가 각자 가진다.
 *
 * - `write`: {uri, extension?, values, cover?: {path, scale, dx, dy, rotation}, ask} → {status: written|failed|denied|unsupported, error?}
 * - `read`: {uri, extension?} → {status: ok|unsupported|failed, tags}  (키는 소문자)
 * - `ensure`: {uri, ask} → Boolean (쓸 수 없는 곡이면 물을 것이 없어 true)
 */
class TagChannel(
    private val context: Context,
    messenger: BinaryMessenger,
    private val store: MediaStoreChannel,
    private val transcoder: TranscoderChannel,
) : NativeChannel(messenger, NAME) {
    private val io = Executors.newSingleThreadExecutor()

    init {
        channel.setMethodCallHandler { call, result ->
            val uri = call.argument<String>("uri")
            if (uri.isNullOrEmpty()) {
                result.error("bad_args", "uri required", null)
                return@setMethodCallHandler
            }
            val extension = call.argument<String>("extension")
            when (call.method) {
                "write" -> {
                    val values = call.argument<Map<String, String>>("values") ?: emptyMap()
                    val cover = call.argument<Map<String, Any>>("cover")
                    val ask = call.argument<Boolean>("ask") ?: false
                    io.execute { write(uri, extension, values, cover, ask, result) }
                }
                "read" -> io.execute { read(uri, extension, result) }
                "ensure" -> io.execute { ensure(uri, call.argument<Boolean>("ask") ?: false, result) }
                else -> result.notImplemented()
            }
        }
    }

    private fun isContent(uri: String) = uri.startsWith("content://")

    /** 형식을 정한다. `content://`는 파일의 mime으로, 경로는 넘어온 확장자(없으면 경로의 확장자)로. */
    private fun formatOf(uri: String, extension: String?): String? =
        if (isContent(uri)) {
            TagFormats.ofMime(store.mimeOf(Uri.parse(uri)))
        } else {
            TagFormats.ofExtension(extension ?: uri.substringAfterLast('.', ""))
        }

    private fun done(result: MethodChannel.Result, payload: Map<String, Any?>) =
        android.os.Handler(android.os.Looper.getMainLooper()).post { result.success(payload) }

    private fun copyToCache(uri: String): File? {
        val dir = File(context.cacheDir, "tag_work").apply { mkdirs() }
        val out = File(dir, "tag_${System.nanoTime()}")
        val input = context.contentResolver.openInputStream(Uri.parse(uri)) ?: return null
        input.use { i -> out.outputStream().use { o -> i.copyTo(o) } }
        return out
    }

    private fun write(uri: String, extension: String?, values: Map<String, String>, cover: Map<String, Any>?, ask: Boolean, result: MethodChannel.Result) {
        val format = try {
            formatOf(uri, extension)
        } catch (e: Exception) {
            null
        }
        if (format == null || !transcoder.isAvailable()) {
            done(result, mapOf("status" to "unsupported"))
            return
        }
        // 커버는 네이티브가 정사각형 PNG로 만들고(못 만들면 커버 없이 글만 쓴다), 형식 함수에는 완성된 PNG만 넘긴다.
        val png = File(context.cacheDir, "tag_cover_${System.nanoTime()}.png")
        val coverPng = cover?.let { c ->
            fun num(key: String, fallback: Double) = (c[key] as? Number)?.toDouble() ?: fallback
            val path = c["path"] as? String
            val ok = path != null && try {
                CoverRender.render(path, num("scale", 1.0), num("dx", 0.0), num("dy", 0.0), num("rotation", 0.0), 512, png)
            } catch (e: Exception) {
                false
            }
            if (ok) png.absolutePath else null
        }
        if (values.isEmpty() && coverPng == null) {
            png.delete()
            done(result, mapOf("status" to "failed", "error" to "nothing to write (cover=${cover != null})"))
            return
        }
        try {
            writeWith(uri, values, coverPng, format, ask, result)
        } finally {
            // 내용 덮어쓰기(동의 창 포함)가 끝날 때까지 PNG는 필요 없다: 태그는 이미 써졌다.
            png.delete()
        }
    }

    private fun writeWith(uri: String, values: Map<String, String>, cover: String?, format: String, ask: Boolean, result: MethodChannel.Result) {
        if (!isContent(uri)) {
            val file = File(uri)
            val out = File("${uri}.tagged")
            try {
                if (!file.exists()) {
                    done(result, mapOf("status" to "unsupported"))
                    return
                }
                val ok = transcoder.tagFile(uri, values, cover, format, out.absolutePath)
                if (ok && out.length() > 0 && out.renameTo(file)) {
                    done(result, mapOf("status" to "written"))
                } else {
                    done(result, mapOf("status" to "failed", "error" to "ffmpeg ok=$ok"))
                }
            } catch (e: Exception) {
                done(result, mapOf("status" to "failed", "error" to (e.message ?: e.toString())))
            } finally {
                out.delete()
            }
            return
        }
        // content://: 캐시로 복사 → 태그 쓰기 → 같은 주소에 덮어쓰기.
        var temp: File? = null
        var tagged: File? = null
        try {
            val t0 = System.currentTimeMillis()
            temp = copyToCache(uri)
            if (temp == null) {
                done(result, mapOf("status" to "denied"))
                return
            }
            val copyMs = System.currentTimeMillis() - t0
            val out = File("${temp.absolutePath}.tagged").also { tagged = it }
            val t1 = System.currentTimeMillis()
            val ok = transcoder.tagFile(temp.absolutePath, values, cover, format, out.absolutePath)
            val tagMs = System.currentTimeMillis() - t1
            if (!ok || out.length() == 0L) {
                MuloLog.d(MuloLog.NATIVE, "MuloTag time format=$format size=${temp.length()}B copy=${copyMs}ms tag=${tagMs}ms (failed)")
                temp.delete()
                out.delete()
                done(result, mapOf("status" to "failed", "error" to "ffmpeg ok=$ok"))
                return
            }
            val size = temp.length()
            temp.delete()
            val t2 = System.currentTimeMillis()
            store.overwriteAudio(Uri.parse(uri), out, ask, object : MethodChannel.Result {
                override fun success(value: Any?) {
                    out.delete()
                    MuloLog.d(MuloLog.NATIVE, "MuloTag time format=$format size=${size}B copy=${copyMs}ms tag=${tagMs}ms overwrite=${System.currentTimeMillis() - t2}ms ok=$value")
                    result.success(mapOf("status" to if (value == true) "written" else "denied"))
                }

                override fun error(code: String, message: String?, details: Any?) {
                    out.delete()
                    result.success(mapOf("status" to "failed", "error" to (message ?: code)))
                }

                override fun notImplemented() {
                    out.delete()
                    result.success(mapOf("status" to "failed", "error" to "not implemented"))
                }
            })
        } catch (e: Exception) {
            temp?.delete()
            tagged?.delete()
            done(result, mapOf("status" to "failed", "error" to (e.message ?: e.toString())))
        }
    }

    /** 안드로이드가 직접 읽는 기본 칸(제목 · 아티스트 · 앨범 · 장르). 파일을 복사하지 않고 주소로 바로 읽는다. 키는 소문자. */
    private fun readStandard(uri: String): Map<String, String> {
        val out = linkedMapOf<String, String>()
        val retriever = android.media.MediaMetadataRetriever()
        try {
            if (isContent(uri)) retriever.setDataSource(context, Uri.parse(uri)) else retriever.setDataSource(uri)
            val keys = mapOf(
                "title" to android.media.MediaMetadataRetriever.METADATA_KEY_TITLE,
                "artist" to android.media.MediaMetadataRetriever.METADATA_KEY_ARTIST,
                "album" to android.media.MediaMetadataRetriever.METADATA_KEY_ALBUM,
                "genre" to android.media.MediaMetadataRetriever.METADATA_KEY_GENRE,
            )
            for ((name, key) in keys) retriever.extractMetadata(key)?.takeIf { it.isNotBlank() }?.let { out[name] = it }
        } finally {
            retriever.release()
        }
        return out
    }

    /**
     * 기본 칸은 안드로이드가 읽고(ffmpeg가 없는 lite도 된다), 앱 전용 칸(`cover_*`: 커버 원본 · 확대 · 색)은
     * 안드로이드가 못 읽어서 ffmpeg가 있을 때만 파일을 읽어 채운다.
     */
    private fun read(uri: String, extension: String?, result: MethodChannel.Result) {
        var temp: File? = null
        try {
            if (formatOf(uri, extension) == null) {
                done(result, mapOf("status" to "unsupported", "tags" to emptyMap<String, String>()))
                return
            }
            if (!isContent(uri) && !File(uri).exists()) {
                done(result, mapOf("status" to "failed", "tags" to emptyMap<String, String>()))
                return
            }
            val tags = linkedMapOf<String, String>()
            tags.putAll(readStandard(uri))
            if (transcoder.isAvailable()) {
                val path = if (isContent(uri)) {
                    temp = copyToCache(uri)
                    temp?.absolutePath
                } else {
                    uri
                }
                if (path != null) {
                    for ((k, v) in transcoder.readTags(path)) if (k.startsWith("cover_")) tags[k] = v
                }
            }
            done(result, mapOf("status" to "ok", "tags" to tags))
        } catch (e: Exception) {
            done(result, mapOf("status" to "failed", "error" to (e.message ?: e.toString()), "tags" to emptyMap<String, String>()))
        } finally {
            temp?.delete()
        }
    }

    private fun ensure(uri: String, ask: Boolean, result: MethodChannel.Result) {
        val needed = isContent(uri) && transcoder.isAvailable() && try {
            TagFormats.ofMime(store.mimeOf(Uri.parse(uri))) != null
        } catch (e: Exception) {
            false
        }
        if (!needed) {
            done(result, mapOf("ok" to true))
            return
        }
        // ensureWrite는 Boolean을 돌려주므로 그대로 Dart에 넘기되 형식을 맞추려고 한 번 감싼다.
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            store.ensureWrite(Uri.parse(uri), ask, object : MethodChannel.Result {
                override fun success(value: Any?) = result.success(mapOf("ok" to (value == true)))
                override fun error(code: String, message: String?, details: Any?) = result.success(mapOf("ok" to true))
                override fun notImplemented() = result.success(mapOf("ok" to true))
            })
        }
    }

    override fun dispose() {
        super.dispose()
        io.shutdownNow()
    }

    companion object {
        const val NAME = "music_app/tags"
    }
}
