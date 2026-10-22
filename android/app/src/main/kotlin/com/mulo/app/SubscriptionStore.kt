package com.mulo.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * 구독 채널 하나 (Dart가 넘긴 값). [baselineMs]보다 늦게 올라온 영상이 새 영상이다.
 * [categories]가 비어 있지 않으면 그 유튜브 분류의 영상만 알린다 (분류를 모르는 영상은 알린다).
 */
data class SubscribedChannel(
    val id: String,
    val name: String,
    val baselineMs: Long,
    val categories: Set<String> = emptySet(),
)

/**
 * 백그라운드 확인에 필요한 값을 SharedPreferences에 보관한다 (앱이 꺼져 있어도 워커가 읽는다).
 * 채널 목록 · 알림 글은 Dart가 `sync`로 덮어쓰고, 채널별로 이미 알린 가장 늦은 영상 시각은 여기서 관리한다.
 */
object SubscriptionStore {
    private const val PREFS = "mulo_subscriptions"
    private const val KEY_CONFIG = "config"
    private const val KEY_NOTIFIED = "notified"
    private const val KEY_LAST_RUN = "lastRun"

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(context: Context, args: Map<String, Any?>) {
        val channels = JSONArray()
        val ids = HashSet<String>()
        (args["channels"] as? List<*>)?.forEach { raw ->
            val m = raw as? Map<*, *> ?: return@forEach
            val id = m["id"] as? String ?: return@forEach
            ids.add(id)
            channels.put(
                JSONObject()
                    .put("id", id)
                    .put("name", m["name"] as? String ?: "")
                    .put("baselineMs", (m["baselineMs"] as? Number)?.toLong() ?: 0L)
                    .put("categories", JSONArray((m["categories"] as? List<*>)?.filterIsInstance<String>() ?: emptyList<String>())),
            )
        }
        val config = JSONObject()
            .put("channels", channels)
            .put("channelName", args["channelName"] as? String ?: "")
            .put("title", args["title"] as? String ?: "")
            .put("body", args["body"] as? String ?: "")
            .put("downloadLabel", args["downloadLabel"] as? String ?: "")
            .put("cancelLabel", args["cancelLabel"] as? String ?: "")
            .put("color", (args["color"] as? Number)?.toInt() ?: 0)
        // 구독을 해제한 채널의 알림 기록은 버린다.
        val notified = loadNotified(context)
        notified.keys().asSequence().toList().forEach { if (it !in ids) notified.remove(it) }
        prefs(context).edit()
            .putString(KEY_CONFIG, config.toString())
            .putString(KEY_NOTIFIED, notified.toString())
            .apply()
    }

    private fun config(context: Context): JSONObject? =
        prefs(context).getString(KEY_CONFIG, null)?.let { runCatching { JSONObject(it) }.getOrNull() }

    fun channels(context: Context): List<SubscribedChannel> {
        val arr = config(context)?.optJSONArray("channels") ?: return emptyList()
        return (0 until arr.length()).mapNotNull { i ->
            val o = arr.optJSONObject(i) ?: return@mapNotNull null
            val cats = o.optJSONArray("categories")
            SubscribedChannel(
                o.getString("id"),
                o.optString("name"),
                o.optLong("baselineMs"),
                if (cats == null) emptySet() else (0 until cats.length()).map { cats.getString(it) }.toSet(),
            )
        }
    }

    fun text(context: Context, key: String): String = config(context)?.optString(key) ?: ""

    fun color(context: Context): Int = config(context)?.optInt("color", 0) ?: 0

    private fun loadNotified(context: Context): JSONObject =
        prefs(context).getString(KEY_NOTIFIED, null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() } ?: JSONObject()

    /** 이 채널에서 이미 알린 가장 늦은 영상 시각 (없으면 0). */
    fun notifiedUntil(context: Context, channelId: String): Long =
        loadNotified(context).optLong(channelId, 0L)

    fun markNotified(context: Context, until: Map<String, Long>) {
        val notified = loadNotified(context)
        until.forEach { (id, ms) -> if (ms > notified.optLong(id, 0L)) notified.put(id, ms) }
        prefs(context).edit().putString(KEY_NOTIFIED, notified.toString()).apply()
    }

    /** 마지막 확인의 결과 (설정 화면에서 보여 주는 진단용). */
    fun saveRun(context: Context, run: Map<String, Any>) {
        prefs(context).edit().putString(KEY_LAST_RUN, JSONObject(run).toString()).apply()
    }

    fun lastRun(context: Context): Map<String, Any?> {
        val o = prefs(context).getString(KEY_LAST_RUN, null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return emptyMap()
        return o.keys().asSequence().associateWith { o.opt(it) }
    }
}
