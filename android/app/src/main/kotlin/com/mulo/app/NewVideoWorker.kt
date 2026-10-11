package com.mulo.app

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import java.net.HttpURLConnection
import java.net.URL
import java.time.OffsetDateTime
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * 구독 채널의 새 영상을 주기적으로 확인한다. 유튜브 채널 RSS(`feeds/videos.xml`)를 읽어
 * 기준 시각 이후에 올라온 영상이 있으면 알림 하나로 알린다. 받지는 않는다 (앱에서 골라서 받는다).
 */
class NewVideoWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val channels = SubscriptionStore.channels(applicationContext)
        if (channels.isEmpty()) return@withContext Result.success()

        var total = 0
        val names = mutableListOf<String>()
        val latest = HashMap<String, Long>()
        for (c in channels) {
            val videos = try {
                fetchVideos(c.id)
            } catch (e: Exception) {
                // 이 채널은 다음 주기에 다시 본다.
                continue
            }
            // 앱에서 이미 본 시각과 이미 알린 시각 중 늦은 쪽 이후만 새 영상이다.
            val since = maxOf(c.baselineMs, SubscriptionStore.notifiedUntil(applicationContext, c.id))
            var fresh = videos.filter { it.publishedMs > since }
            // 분류를 거르는 채널은 새 영상마다 분류를 읽어 조건에 맞는 것만 남긴다 (읽지 못하면 남긴다).
            if (c.categories.isNotEmpty()) {
                fresh = fresh.take(MAX_CATEGORY_LOOKUPS).filter { v ->
                    val category = try {
                        fetchCategory(v.id)
                    } catch (e: Exception) {
                        null
                    }
                    category == null || category in c.categories
                }
            }
            if (fresh.isNotEmpty()) {
                total += fresh.size
                names.add(c.name)
                latest[c.id] = fresh.maxOf { it.publishedMs }
            }
        }
        if (total > 0) {
            NewVideoNotifications.show(applicationContext, names, total)
            SubscriptionStore.markNotified(applicationContext, latest)
        }
        Result.success()
    }

    private data class Video(val id: String, val publishedMs: Long)

    /** 채널 RSS에서 영상들의 id · 올린 시각(ms)을 읽는다. */
    private fun fetchVideos(channelId: String): List<Video> {
        val url = URL("https://www.youtube.com/feeds/videos.xml?channel_id=$channelId")
        val conn = url.openConnection() as HttpURLConnection
        try {
            conn.connectTimeout = 10_000
            conn.readTimeout = 20_000
            conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36")
            if (conn.responseCode != 200) throw IllegalStateException("feed ${conn.responseCode}")
            val xml = conn.inputStream.bufferedReader().use { it.readText() }
            return ENTRY.findAll(xml).mapNotNull {
                val ms = runCatching { OffsetDateTime.parse(it.groupValues[2].trim()).toInstant().toEpochMilli() }.getOrNull()
                if (ms == null) null else Video(it.groupValues[1].trim(), ms)
            }.toList()
        } finally {
            conn.disconnect()
        }
    }

    /** 영상 페이지에서 유튜브 분류 이름(예: Music)을 읽는다. 못 찾으면 null. */
    private fun fetchCategory(videoId: String): String? {
        val conn = URL("https://www.youtube.com/watch?v=$videoId").openConnection() as HttpURLConnection
        try {
            conn.connectTimeout = 10_000
            conn.readTimeout = 20_000
            conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36")
            conn.setRequestProperty("Accept-Language", "en-US,en;q=0.8")
            if (conn.responseCode != 200) return null
            val html = conn.inputStream.bufferedReader().use { it.readText() }
            return CATEGORY.find(html)?.groupValues?.get(1)?.replace("\\u0026", "&")
        } finally {
            conn.disconnect()
        }
    }

    companion object {
        private val ENTRY = Regex("<entry>[\\s\\S]*?<yt:videoId>([^<]+)</yt:videoId>[\\s\\S]*?<published>([^<]+)</published>[\\s\\S]*?</entry>")
        private val CATEGORY = Regex("\"category\":\"([^\"]+)\"")

        /** 한 번에 분류를 읽어 볼 새 영상 수 (많이 쌓였을 때 요청이 폭주하지 않게). */
        private const val MAX_CATEGORY_LOOKUPS = 10
    }
}
