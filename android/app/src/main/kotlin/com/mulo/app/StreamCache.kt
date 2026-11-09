package com.mulo.app

import android.content.Context
import android.net.Uri
import androidx.media3.common.util.UnstableApi
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import java.io.File

/**
 * 스트리밍(받지 않고 바로 듣기) 소리 · 영상의 임시 저장소. 들은 부분을 앱 캐시 폴더에 쌓아 두었다가
 * 같은 곡을 다시 들으면 네트워크 없이 거기서 읽는다. 보관함 곡이 아니고 파일로 보이지도 않는다.
 *
 * 용량 한도를 넘으면 가장 오래 안 쓴 것부터 지운다 (LRU). 한도 0은 끔.
 * 스트림 주소는 틀 때마다 서명이 바뀌어서, 주소 대신 영상 id + 형식(itag)을 키로 쓴다.
 */
@UnstableApi
object StreamCache {
    private const val PREFS = "stream_cache"
    private const val KEY_LIMIT = "limit_bytes"
    private const val DEFAULT_LIMIT = 500L * 1024 * 1024
    private const val DIR = "stream_cache"

    private var cache: SimpleCache? = null
    private var dbProvider: StandaloneDatabaseProvider? = null

    fun limitBytes(context: Context): Long =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong(KEY_LIMIT, DEFAULT_LIMIT)

    /** 한도를 바꾼다. 쓰던 캐시는 닫고 다음에 새 한도로 연다 (플레이어가 쓰는 중이면 먼저 멈춰야 한다). */
    @Synchronized
    fun setLimitBytes(context: Context, bytes: Long) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putLong(KEY_LIMIT, bytes).apply()
        close()
    }

    @Synchronized
    private fun open(context: Context): SimpleCache? {
        val limit = limitBytes(context)
        if (limit <= 0L) return null
        cache?.let { return it }
        return try {
            val app = context.applicationContext
            val db = dbProvider ?: StandaloneDatabaseProvider(app).also { dbProvider = it }
            SimpleCache(File(app.cacheDir, DIR), LeastRecentlyUsedCacheEvictor(limit), db).also { cache = it }
        } catch (e: Exception) {
            // 캐시를 못 열어도 재생은 되어야 한다.
            MuloLog.e(MuloLog.NATIVE, "스트리밍 캐시 열기 실패", e)
            null
        }
    }

    @Synchronized
    fun close() {
        try { cache?.release() } catch (_: Exception) {}
        cache = null
    }

    /** [upstream]을 캐시로 감싼다. 캐시가 꺼져 있거나 못 열면 [upstream] 그대로. */
    fun wrap(context: Context, upstream: DataSource.Factory): DataSource.Factory {
        val c = open(context) ?: return upstream
        return CacheDataSource.Factory()
            .setCache(c)
            .setUpstreamDataSourceFactory(upstream)
            .setCacheKeyFactory { spec -> keyOf(spec.uri) }
            .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
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
