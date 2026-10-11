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
            val published = try {
                fetchPublishedTimes(c.id)
            } catch (e: Exception) {
                // 이 채널은 다음 주기에 다시 본다.
                continue
            }
            // 앱에서 이미 본 시각과 이미 알린 시각 중 늦은 쪽 이후만 새 영상이다.
            val since = maxOf(c.baselineMs, SubscriptionStore.notifiedUntil(applicationContext, c.id))
            val fresh = published.filter { it > since }
            if (fresh.isNotEmpty()) {
                total += fresh.size
                names.add(c.name)
                latest[c.id] = fresh.max()
            }
        }
        if (total > 0) {
            NewVideoNotifications.show(applicationContext, names, total)
            SubscriptionStore.markNotified(applicationContext, latest)
        }
        Result.success()
    }

    /** 채널 RSS에서 영상들의 올린 시각(ms)을 읽는다. */
    private fun fetchPublishedTimes(channelId: String): List<Long> {
        val url = URL("https://www.youtube.com/feeds/videos.xml?channel_id=$channelId")
        val conn = url.openConnection() as HttpURLConnection
        try {
            conn.connectTimeout = 10_000
            conn.readTimeout = 20_000
            conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36")
            if (conn.responseCode != 200) throw IllegalStateException("feed ${conn.responseCode}")
            val xml = conn.inputStream.bufferedReader().use { it.readText() }
            return PUBLISHED.findAll(xml).mapNotNull {
                runCatching { OffsetDateTime.parse(it.groupValues[1].trim()).toInstant().toEpochMilli() }.getOrNull()
            }.toList()
        } finally {
            conn.disconnect()
        }
    }

    companion object {
        private val PUBLISHED = Regex("<entry>[\\s\\S]*?<published>([^<]+)</published>[\\s\\S]*?</entry>")
    }
}
