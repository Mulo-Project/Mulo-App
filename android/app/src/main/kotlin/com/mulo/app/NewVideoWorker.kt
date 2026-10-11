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
 * 기준 시각 이후에 올라온 영상(채널에 분류 조건이 있으면 맞는 것만)마다 알림을 띄운다.
 * 알림의 "바로 받기" 버튼으로 앱에서 받는다. 이 워커가 직접 받지는 않는다.
 */
class NewVideoWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val channels = SubscriptionStore.channels(applicationContext)
        if (channels.isEmpty()) return@withContext Result.success()

        val toNotify = mutableListOf<NewVideo>()
        val latest = HashMap<String, Long>()
        for (c in channels) {
            val videos = try {
                fetchVideos(c)
            } catch (e: Exception) {
                // 이 채널은 다음 주기에 다시 본다.
                continue
            }
            // 앱에서 이미 본 시각과 이미 알린 시각 중 늦은 쪽 이후만 새 영상이다.
            val since = maxOf(c.baselineMs, SubscriptionStore.notifiedUntil(applicationContext, c.id))
            val fresh = videos.filter { it.publishedMs > since }
            if (fresh.isEmpty()) continue
            latest[c.id] = fresh.maxOf { it.publishedMs }
            // 분류를 거르는 채널은 새 영상마다 분류를 읽어 조건에 맞는 것만 남긴다 (읽지 못하면 남긴다).
            toNotify += if (c.categories.isEmpty()) fresh else fresh.take(MAX_CATEGORY_LOOKUPS).filter { v ->
                val category = try {
                    fetchCategory(v.id)
                } catch (e: Exception) {
                    null
                }
                category == null || category in c.categories
            }
        }
        if (toNotify.isNotEmpty()) {
            NewVideoNotifications.showVideos(applicationContext, toNotify)
        }
        SubscriptionStore.markNotified(applicationContext, latest)
        Result.success()
    }

    /** 채널 RSS에서 영상들을 읽는다. */
    private fun fetchVideos(channel: SubscribedChannel): List<NewVideo> {
        val url = URL("https://www.youtube.com/feeds/videos.xml?channel_id=${channel.id}")
        val conn = url.openConnection() as HttpURLConnection
        try {
            conn.connectTimeout = 10_000
            conn.readTimeout = 20_000
            conn.setRequestProperty("User-Agent", USER_AGENT)
            if (conn.responseCode != 200) throw IllegalStateException("feed ${conn.responseCode}")
            val xml = conn.inputStream.bufferedReader().use { it.readText() }
            return ENTRY.findAll(xml).mapNotNull { m ->
                val body = m.groupValues[1]
                val id = tag(body, "yt:videoId") ?: return@mapNotNull null
                val ms = tag(body, "published")?.let {
                    runCatching { OffsetDateTime.parse(it).toInstant().toEpochMilli() }.getOrNull()
                } ?: return@mapNotNull null
                NewVideo(
                    id = id,
                    title = tag(body, "title")?.let(::unescape) ?: id,
                    channelId = channel.id,
                    channelName = channel.name,
                    thumbnailUrl = THUMBNAIL.find(body)?.groupValues?.get(1),
                    publishedMs = ms,
                )
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
            conn.setRequestProperty("User-Agent", USER_AGENT)
            conn.setRequestProperty("Accept-Language", "en-US,en;q=0.8")
            if (conn.responseCode != 200) return null
            val html = conn.inputStream.bufferedReader().use { it.readText() }
            return CATEGORY.find(html)?.groupValues?.get(1)?.replace("\\u0026", "&")
        } finally {
            conn.disconnect()
        }
    }

    private fun tag(text: String, name: String): String? =
        Regex("<$name>([^<]*)</$name>").find(text)?.groupValues?.get(1)?.trim()

    private fun unescape(s: String): String = s
        .replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", "\"")
        .replace("&apos;", "'").replace("&#39;", "'").replace("&amp;", "&")

    companion object {
        private const val USER_AGENT = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36"
        private val ENTRY = Regex("<entry>([\\s\\S]*?)</entry>")
        private val THUMBNAIL = Regex("<media:thumbnail[^>]*\\burl=\"([^\"]+)\"")
        private val CATEGORY = Regex("\"category\":\"([^\"]+)\"")

        /** 한 번에 분류를 읽어 볼 새 영상 수 (많이 쌓였을 때 요청이 폭주하지 않게). */
        private const val MAX_CATEGORY_LOOKUPS = 10
    }
}

/** 알릴 새 영상 하나. */
data class NewVideo(
    val id: String,
    val title: String,
    val channelId: String,
    val channelName: String,
    val thumbnailUrl: String?,
    val publishedMs: Long,
)
