package com.mulo.app

import android.content.Context
import android.net.Uri
import androidx.media3.common.util.UnstableApi
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.TransferListener
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.CacheWriter
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.NoOpCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import java.io.File

/**
 * 스트리밍(받지 않고 바로 듣기) 소리 · 영상의 임시 저장소. 들은 부분을 앱 캐시 폴더에 쌓아 두었다가
 * 같은 곡을 다시 들으면 네트워크 없이 거기서 읽는다. 보관함 곡이 아니고 파일로 보이지도 않는다.
 *
 * 용량 한도를 넘으면 가장 오래 안 쓴 것부터 지운다 (LRU). 한도는 500 MB 고정.
 * 스트림 주소는 틀 때마다 서명이 바뀌어서, 주소 대신 영상 id + 형식(itag)을 키로 쓴다.
 */
@UnstableApi
object StreamCache {
    /** 용량 한도: 고정 500 MB. */
    private const val LIMIT_BYTES = 500L * 1024 * 1024
    private const val DIR = "stream_cache"

    private const val SAVED_DIR = "saved_streams"

    private var cache: SimpleCache? = null
    private var savedCache: SimpleCache? = null

    /** 보관한 영상 id. 이 영상의 데이터는 임시 저장소(LRU)가 아니라 보관 저장소에 쌓여 지워지지 않는다. */
    @Volatile
    private var savedIds: Set<String> = emptySet()
    private val fills = HashMap<String, CacheWriter>()
    private var dbProvider: StandaloneDatabaseProvider? = null

    @Suppress("UNUSED_PARAMETER")
    fun limitBytes(context: Context): Long = LIMIT_BYTES

    @Synchronized
    private fun open(context: Context): SimpleCache? {
        cache?.let { return it }
        return try {
            val app = context.applicationContext
            val db = dbProvider ?: StandaloneDatabaseProvider(app).also { dbProvider = it }
            SimpleCache(File(app.cacheDir, DIR), LeastRecentlyUsedCacheEvictor(LIMIT_BYTES), db).also { cache = it }
        } catch (e: Exception) {
            // 캐시를 못 열어도 재생은 되어야 한다.
            MuloLog.e(MuloLog.NATIVE, "스트리밍 캐시 열기 실패", e)
            null
        }
    }

    @Synchronized
    private fun openSaved(context: Context): SimpleCache? {
        savedCache?.let { return it }
        return try {
            val app = context.applicationContext
            val db = dbProvider ?: StandaloneDatabaseProvider(app).also { dbProvider = it }
            // 내려받은 곡처럼 앱이 지우기 전에는 남는다: 보관함에서 빼거나 앱 데이터를 지울 때만 사라진다.
            SimpleCache(File(app.filesDir, SAVED_DIR), NoOpCacheEvictor(), db).also { savedCache = it }
        } catch (e: Exception) {
            MuloLog.e(MuloLog.NATIVE, "보관 저장소 열기 실패", e)
            null
        }
    }

    @Synchronized
    fun close() {
        try { cache?.release() } catch (_: Exception) {}
        cache = null
    }

    /** [upstream]을 캐시로 감싼다. 캐시를 못 열면 [upstream] 그대로. */
    fun wrap(context: Context, upstream: DataSource.Factory): DataSource.Factory {
        val c = open(context) ?: return upstream
        val temp = cacheFactory(c, upstream)
        val saved = openSaved(context)?.let { cacheFactory(it, upstream) } ?: return temp
        // 보관한 영상은 보관 저장소로, 나머지는 임시 저장소로 보낸다.
        return DataSource.Factory { RoutingDataSource(temp.createDataSource(), saved.createDataSource()) }
    }

    private fun cacheFactory(c: SimpleCache, upstream: DataSource.Factory) = CacheDataSource.Factory()
        .setCache(c)
        .setUpstreamDataSourceFactory(upstream)
        .setCacheKeyFactory { spec -> keyOf(spec.uri) }
        .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)

    /** 요청한 주소의 영상 id가 보관 목록에 있으면 [saved]로, 아니면 [temp]로 읽는다. */
    private class RoutingDataSource(private val temp: DataSource, private val saved: DataSource) : DataSource {
        private var active: DataSource? = null

        override fun addTransferListener(listener: TransferListener) {
            temp.addTransferListener(listener)
            saved.addTransferListener(listener)
        }

        override fun open(dataSpec: DataSpec): Long {
            val id = dataSpec.uri.getQueryParameter("id")
            val target = if (id != null && id in savedIds) saved else temp
            active = target
            return target.open(dataSpec)
        }

        override fun read(buffer: ByteArray, offset: Int, length: Int): Int =
            active?.read(buffer, offset, length) ?: -1

        override fun getUri(): Uri? = active?.uri

        override fun getResponseHeaders(): Map<String, List<String>> = active?.responseHeaders ?: emptyMap()

        override fun close() {
            try { active?.close() } finally { active = null }
        }
    }

    /** 보관한 영상 id 목록을 바꾼다 (Dart가 시작할 때와 보관을 바꿀 때마다 보낸다). */
    fun setSavedIds(ids: Collection<String>) {
        savedIds = ids.toSet()
    }

    fun addSavedId(streamId: String) {
        savedIds = savedIds + streamId
    }

    /**
     * [url]의 영상을 통째로 보관 저장소에 받아 둔다 (끝나면 [done]에 성공 여부). 이미 있는 부분은 건너뛴다.
     * 같은 영상 id를 이미 받는 중이면 아무 일도 없다.
     */
    fun fillSaved(context: Context, id: String, url: String, headers: Map<String, String>, done: (Boolean) -> Unit) {
        val c = openSaved(context) ?: return done(false)
        val key = "$id|$url"
        synchronized(this) {
            if (fills.containsKey(key)) return
        }
        val http = androidx.media3.datasource.DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)
        val source = cacheFactory(c, http).createDataSource()
        val uri = Uri.parse(url)
        val writer = CacheWriter(source, DataSpec(uri), null, null)
        synchronized(this) { fills[key] = writer }
        Thread({
            val ok = try {
                writer.cache()
                true
            } catch (e: Exception) {
                MuloLog.e(MuloLog.NATIVE, "영상 보관 받기 실패", e)
                false
            } finally {
                synchronized(this) { fills.remove(key) }
            }
            done(ok)
        }, "mulo-save-stream").start()
    }

    /** 보관 저장소에서 스트림 id([streamId]) 영상의 데이터를 지우고 받던 것도 멈춘다. [id]는 영상 id. */
    @Synchronized
    fun removeSaved(context: Context, id: String, streamId: String?) {
        fills.filterKeys { it.startsWith("$id|") }.forEach { (k, w) ->
            w.cancel()
            fills.remove(k)
        }
        if (streamId == null) return
        savedIds = savedIds - streamId
        val c = openSaved(context) ?: return
        for (key in c.keys.toList()) {
            if (key.startsWith("yt:$streamId:")) c.removeResource(key)
        }
    }

    /** 지금 쌓인 크기 (바이트). */
    @Synchronized
    fun usedBytes(context: Context): Long = open(context)?.cacheSpace ?: dirSize(File(context.cacheDir, DIR))

    /** 모두 지운다. */
    @Synchronized
    fun clear(context: Context) {
        close()
        File(context.cacheDir, DIR).deleteRecursively()
    }

    /** googlevideo 주소는 `id` + `itag`(+`mime`)가 같은 내용을 가리킨다. 모르는 주소는 쿼리를 뺀 주소. */
    internal fun keyOf(uri: Uri): String {
        val id = uri.getQueryParameter("id")
        val itag = uri.getQueryParameter("itag")
        if (id != null && itag != null) return "yt:$id:$itag"
        return uri.buildUpon().clearQuery().build().toString()
    }

    private fun dirSize(dir: File): Long =
        if (!dir.exists()) 0L else dir.walkTopDown().filter { it.isFile }.sumOf { it.length() }
}
