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
import androidx.media3.exoplayer.hls.offline.HlsDownloader
import androidx.media3.common.MediaItem
import java.io.File

/**
 * 스트리밍(받지 않고 바로 듣기) 소리 · 영상의 임시 저장소. 들은 부분을 앱 캐시 폴더에 쌓아 두었다가
 * 같은 곡을 다시 들으면 네트워크 없이 거기서 읽는다. 보관함 곡이 아니고 파일로 보이지도 않는다.
 *
 * 용량 한도를 넘으면 가장 오래 안 쓴 것부터 지운다 (LRU). 한도는 설정에서 고른다 (기본 500 MB).
 * 스트림 주소는 틀 때마다 서명이 바뀌어서, 주소 대신 영상 id + 형식(itag)을 키로 쓴다.
 */
@UnstableApi
object StreamCache {
    /** 임시 저장소 용량 한도 기본값 500 MB (설정에서 바꾼다). */
    private const val DEFAULT_LIMIT_BYTES = 500L * 1024 * 1024
    private const val MIN_TEMP_BYTES = 32L * 1024 * 1024
    private const val PREFS = "mulo_stream_cache"
    private const val KEY_LIMIT = "limit"

    private const val DIR = "stream_cache"

    private const val SAVED_DIR = "saved_streams"

    private var cache: SimpleCache? = null
    private var savedCache: SimpleCache? = null

    /** 보관한 영상 id. 이 영상의 데이터는 임시 저장소(LRU)가 아니라 보관 저장소에 쌓여 지워지지 않는다. */
    @Volatile
    private var savedIds: Set<String> = emptySet()
    private val fills = HashMap<String, Fill>()
    private var dbProvider: StandaloneDatabaseProvider? = null

    /**
     * 듣기용 임시 캐시가 쓸 수 있는 크기: 전체 한도에서 저장한 음원이 쓰는 만큼을 뺀다 (저장분도 한도에 포함).
     * 저장분이 한도를 채워도 듣기 캐시는 최소한은 쓴다. 저장소를 새로 열 때 적용된다.
     */
    private fun tempLimitBytes(context: Context): Long =
        (limitBytes(context) - savedBytes(context)).coerceAtLeast(MIN_TEMP_BYTES)

    fun limitBytes(context: Context): Long =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong(KEY_LIMIT, DEFAULT_LIMIT_BYTES)

    /** 한도를 바꾼다. 쌓인 것은 그대로 두고, 저장소를 닫아 다음에 새 한도로 열게 한다 (줄이면 쓰면서 오래된 것부터 정리된다). */
    @Synchronized
    fun setLimit(context: Context, bytes: Long) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putLong(KEY_LIMIT, bytes).apply()
        close()
    }

    @Synchronized
    private fun open(context: Context): SimpleCache? {
        cache?.let { return it }
        return try {
            val app = context.applicationContext
            val db = dbProvider ?: StandaloneDatabaseProvider(app).also { dbProvider = it }
            SimpleCache(File(app.cacheDir, DIR), LeastRecentlyUsedCacheEvictor(tempLimitBytes(app)), db).also { cache = it }
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
        val savedSimple = openSaved(context) ?: return temp
        val saved = cacheFactory(savedSimple, upstream)
        // 보관한 영상은 보관 저장소로, 나머지는 임시 저장소로 보낸다.
        // 이미 보관 저장소에 데이터가 있는 주소(HLS 조각 등 id가 없는 곳)도 보관 저장소로 읽는다.
        val inSaved = { uri: Uri -> savedSimple.getCachedSpans(keyOf(uri)).isNotEmpty() }
        return DataSource.Factory { RoutingDataSource(temp.createDataSource(), saved.createDataSource(), inSaved) }
    }

    private fun cacheFactory(c: SimpleCache, upstream: DataSource.Factory) = CacheDataSource.Factory()
        .setCache(c)
        .setUpstreamDataSourceFactory(upstream)
        .setCacheKeyFactory { spec -> keyOf(spec.uri) }
        .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)

    /** 요청한 주소의 영상 id가 보관 목록에 있으면 [saved]로, 아니면 [temp]로 읽는다. */
    private class RoutingDataSource(
        private val temp: DataSource,
        private val saved: DataSource,
        private val inSavedCache: (Uri) -> Boolean,
    ) : DataSource {
        private var active: DataSource? = null

        override fun addTransferListener(listener: TransferListener) {
            temp.addTransferListener(listener)
            saved.addTransferListener(listener)
        }

        override fun open(dataSpec: DataSpec): Long {
            val id = dataSpec.uri.getQueryParameter("id")
            // 유튜브는 주소의 id로, id가 없는 곳(사운드클라우드 등)은 캐시 키로 보관 여부를 가른다.
            val inSaved = (id != null && id in savedIds) || keyOf(dataSpec.uri) in savedIds || inSavedCache(dataSpec.uri)
            val target = if (inSaved) saved else temp
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

    /** 받는 중인 보관 한 건. 지우면 [cancelled]를 세우고 지금 받는 것도 멈춘다. */
    private class Fill {
        @Volatile var cancelled = false
        val writers: MutableSet<CacheWriter> = java.util.concurrent.ConcurrentHashMap.newKeySet()
        @Volatile var hls: HlsDownloader? = null
    }

    /** 한 번에 받는 조각 수와 조각 크기. 한 줄로 받으면 유튜브가 속도를 깎아서, 나눠 동시에 받는다. */
    private const val PARALLEL = 8
    private const val MIN_CHUNK_BYTES = 512L * 1024
    private const val MAX_CHUNK_BYTES = 4L * 1024 * 1024

    /** 파일 크기를 [PARALLEL]개쯤으로 나누되 조각은 512KB~4MB. 연결마다 속도가 깎여도 합쳐서 빨라지게 잘게 나눈다. */
    private fun chunkSize(len: Long): Long =
        ((len + PARALLEL - 1) / PARALLEL).coerceIn(MIN_CHUNK_BYTES, MAX_CHUNK_BYTES)

    /** 서버가 알려 주는 전체 크기. 모르면 -1. */
    private fun contentLength(url: String, headers: Map<String, String>): Long {
        val src = androidx.media3.datasource.DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)
            .createDataSource()
        return try {
            val n = src.open(DataSpec(Uri.parse(url)))
            if (n == androidx.media3.common.C.LENGTH_UNSET.toLong()) -1L else n
        } catch (_: Exception) {
            -1L
        } finally {
            try { src.close() } catch (_: Exception) {}
        }
    }

    /**
     * [targets](주소 · 헤더, 영상 전용 + 소리 전용처럼 여럿일 수 있다)를 통째로 보관 저장소에 받아 둔다.
     * 주소들은 동시에, 한 주소는 조각으로 나눠 동시에 받는다. 미리 듣기로 이미 임시 저장소에 쌓인 부분은 다시 받지 않고 거기서 옮긴다.
     * 끝나면 [done]에 성공 여부, 받는 동안 [progress]에 0~100. 이미 있는 부분은 건너뛴다. 같은 영상 id를 이미 받는 중이면 아무 일도 없다.
     */
    fun fillSaved(
        context: Context,
        id: String,
        targets: List<Pair<String, Map<String, String>>>,
        progress: (Int) -> Unit = {},
        done: (Boolean) -> Unit,
    ) {
        val c = openSaved(context) ?: return done(false)
        val temp = open(context)
        val fill = Fill()
        synchronized(this) {
            if (fills.containsKey(id)) return
            fills[id] = fill
        }
        Thread({
            var ok = true
            val startedAt = System.currentTimeMillis()
            val pool = java.util.concurrent.Executors.newFixedThreadPool(PARALLEL)
            try {
                // 한 요청: 위치 · 길이 조각 하나. 진행은 조각마다 받은 바이트를 모아 센다.
                class Job(val factory: DataSource.Factory, val spec: DataSpec, val total: Long)
                val jobs = ArrayList<Job>()
                var total = 0L
                var unknown = false
                for ((url, headers) in targets) {
                    if (Uri.parse(url).path?.contains(".m3u8") == true) continue
                    val http = androidx.media3.datasource.DefaultHttpDataSource.Factory()
                        .setAllowCrossProtocolRedirects(true)
                        .setDefaultRequestProperties(headers)
                    // 임시 저장소는 읽기만 한다 (미리 듣던 부분 재사용, 새로 받는 것을 거기에 또 쓰지 않는다).
                    val upstream: DataSource.Factory = if (temp == null) http else CacheDataSource.Factory()
                        .setCache(temp)
                        .setUpstreamDataSourceFactory(http)
                        .setCacheKeyFactory { spec -> keyOf(spec.uri) }
                        .setCacheWriteDataSinkFactory(null)
                        .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
                    val factory = cacheFactory(c, upstream)
                    val uri = Uri.parse(url)
                    val len = contentLength(url, headers)
                    val chunk = chunkSize(len)
                    if (len <= MIN_CHUNK_BYTES) {
                        if (len < 0) unknown = true else total += len
                        jobs.add(Job(factory, DataSpec(uri), len))
                    } else {
                        total += len
                        var pos = 0L
                        while (pos < len) {
                            val n = minOf(chunk, len - pos)
                            jobs.add(Job(factory, DataSpec(uri, pos, n), n))
                            pos += n
                        }
                    }
                }
                MuloLog.d(MuloLog.NATIVE, "보관 받기 시작: 전체 ${total}B 조각 ${jobs.size}개 (준비 ${System.currentTimeMillis() - startedAt}ms)")
                val got = java.util.concurrent.atomic.AtomicLong(0)
                var lastPercent = -1
                val results = jobs.map { job ->
                    pool.submit<Boolean> {
                        if (fill.cancelled) return@submit false
                        var seen = 0L
                        val writer = CacheWriter(job.factory.createDataSource() as CacheDataSource, job.spec, null) { _, bytesCached, _ ->
                            val add = bytesCached - seen
                            seen = bytesCached
                            val sum = got.addAndGet(add)
                            if (!unknown && total > 0) {
                                val pct = (sum * 100 / total).toInt().coerceIn(0, 99)
                                synchronized(fill) {
                                    if (pct != lastPercent) { lastPercent = pct; progress(pct) }
                                }
                            }
                        }
                        fill.writers.add(writer)
                        try { writer.cache(); true } finally { fill.writers.remove(writer) }
                    }
                }
                for (r in results) {
                    try { if (!r.get()) ok = false } catch (e: Exception) { throw e.cause ?: e }
                }
                if (fill.cancelled) ok = false
                // HLS(사운드클라우드 등)는 목록 파일 하나라서 CacheWriter로는 조각이 안 받아진다: 조각까지 모두 받는다.
                for ((url, headers) in targets) {
                    if (!ok) break
                    if (Uri.parse(url).path?.contains(".m3u8") != true) continue
                    val http = androidx.media3.datasource.DefaultHttpDataSource.Factory()
                        .setAllowCrossProtocolRedirects(true)
                        .setDefaultRequestProperties(headers)
                    val before = c.keys.toSet()
                    val downloader = HlsDownloader(MediaItem.fromUri(url), cacheFactory(c, http))
                    fill.hls = downloader
                    downloader.download { _, _, percent ->
                        val pct = percent.toInt().coerceIn(0, 99)
                        synchronized(fill) {
                            if (pct != lastPercent) { lastPercent = pct; progress(pct) }
                        }
                    }
                    rememberKeys(context, id, c.keys - before)
                }
            } catch (e: Exception) {
                MuloLog.e(MuloLog.NATIVE, "영상 보관 받기 실패", e)
                ok = false
            } finally {
                pool.shutdownNow()
                synchronized(this) { fills.remove(id) }
            }
            if (ok) progress(100)
            MuloLog.d(MuloLog.NATIVE, "보관 받기 끝: ok=$ok ${System.currentTimeMillis() - startedAt}ms (주소 ${targets.size}개)")
            done(ok)
        }, "mulo-save-stream").start()
    }

    private fun keysFile(context: Context, id: String) =
        File(File(context.filesDir, "saved_stream_keys").apply { mkdirs() }, id.replace(Regex("[^A-Za-z0-9_-]"), "_"))

    /** HLS처럼 키가 여럿인 곡의 조각 키를 적어 둔다 (지울 때 쓴다). */
    private fun rememberKeys(context: Context, id: String, keys: Collection<String>) {
        try { keysFile(context, id).writeText(keys.joinToString("\n")) } catch (_: Exception) {}
    }

    /** 보관 저장소에서 스트림 id([streamId]) 영상의 데이터를 지우고 받던 것도 멈춘다. [id]는 영상 id. */
    @Synchronized
    fun removeSaved(context: Context, id: String, streamId: String?) {
        fills.remove(id)?.let {
            it.cancelled = true
            it.writers.forEach { w -> w.cancel() }
            it.hls?.cancel()
        }
        // HLS로 받은 조각 키도 함께 지운다.
        keysFile(context, id).takeIf { it.exists() }?.let { f ->
            openSaved(context)?.let { c -> f.readLines().filter { it.isNotEmpty() }.forEach { k -> try { c.removeResource(k) } catch (_: Exception) {} } }
            f.delete()
        }
        if (streamId == null) return
        val ids = streamId.split(",")
        savedIds = savedIds - ids.toSet()
        val c = openSaved(context) ?: return
        for (key in c.keys.toList()) {
            if (ids.any { key.startsWith("yt:$it:") || key == it }) c.removeResource(key)
        }
    }

    /** 지금 쌓인 크기 (바이트). */
    @Synchronized
    fun usedBytes(context: Context): Long = open(context)?.cacheSpace ?: dirSize(File(context.cacheDir, DIR))

    /** 저장한 곡(보관 저장소)이 쓰는 크기 (바이트). */
    @Synchronized
    fun savedBytes(context: Context): Long = openSaved(context)?.cacheSpace ?: 0L

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
