package com.mulo.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** 저장해 둔 대기열 한 곡. */
class StoredItem(
    val id: String,
    val uri: String,
    val title: String,
    val artist: String,
    val album: String,
    val durationMs: Long,
    val art: String?,
)

/** 저장해 둔 재생 상태 (프로세스가 죽은 뒤 이어 재생하려고 쓴다). */
class StoredPlayback(
    val items: List<StoredItem>,
    val index: Int,
    val positionMs: Long,
    val repeat: String,
    val extras: String,
    /** 마지막으로 앱이 받은 알림 내용 (Dart가 보낸 맵). 곡 정보 숨기기 · 버튼 이름을 앱 없이도 지키려고 보관한다. */
    val session: Map<String, Any?>?,
    /** 이어 재생해도 되는 상태인지: 알림을 지웠거나 재생을 끝냈으면 false (블루투스 버튼이 곡을 저절로 켜지 않게). */
    val resumable: Boolean,
)

/**
 * 재생 상태를 SharedPreferences에 보관한다. 블루투스 이어폰 · 차량의 버튼으로 프로세스가 새로 뜰 때
 * 서비스가 대기열을 되살릴 수 있게 한다. 곡 목록은 바뀔 때만, 위치 · 현재 곡 같은 가벼운 값은 자주 쓴다.
 */
object PlaybackStore {
    private const val PREFS = "mulo_playback"
    private const val QUEUE = "queue"
    private const val SESSION = "session"
    private const val INDEX = "index"
    private const val POSITION = "positionMs"
    private const val REPEAT = "repeat"
    private const val EXTRAS = "extras"
    private const val RESUMABLE = "resumable"

    private const val PAUSE_ON_DISCONNECT = "pauseOnDisconnect"
    private const val RESUME_ON_CONNECT = "resumeOnConnect"
    private const val RESUME_WITHOUT_NOTIFICATION = "resumeWithoutNotification"

    private const val SPEED = "playbackSpeed"

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** 블루투스 버튼이 곡을 이어 재생해도 되는지. 프로세스가 아직 없을 때 리시버가 읽는다. */
    fun isResumable(context: Context): Boolean {
        val p = prefs(context)
        return p.getBoolean(RESUMABLE, false) && p.getString(QUEUE, null) != null
    }

    fun setResumable(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean(RESUMABLE, value).apply()
    }

    fun saveQueue(context: Context, items: List<StoredItem>, extras: String) {
        val array = JSONArray()
        for (i in items) {
            array.put(
                JSONObject()
                    .put("id", i.id).put("uri", i.uri).put("title", i.title)
                    .put("artist", i.artist).put("album", i.album)
                    .put("durationMs", i.durationMs).put("art", i.art ?: JSONObject.NULL),
            )
        }
        prefs(context).edit().putString(QUEUE, array.toString()).putString(EXTRAS, extras).apply()
    }

    fun savePosition(context: Context, index: Int, positionMs: Long, repeat: String) {
        prefs(context).edit().putInt(INDEX, index).putLong(POSITION, positionMs).putString(REPEAT, repeat).apply()
    }

    /**
     * 재생이 멈춘 이유를 최근 20개까지 남긴다 (오래 두면 재생이 끊기는 문제를 추적하는 진단용).
     * `adb shell run-as com.mulo.app cat shared_prefs/mulo_playback.xml`의 `stopLog`로 읽는다.
     */
    fun logStop(context: Context, text: String) {
        val stamp = java.text.SimpleDateFormat("MM-dd HH:mm:ss", java.util.Locale.US).format(java.util.Date())
        val lines = (prefs(context).getString("stopLog", "") ?: "").split("\n").filter { it.isNotBlank() }
        prefs(context).edit().putString("stopLog", (lines + "$stamp $text").takeLast(20).joinToString("\n")).apply()
    }

    fun saveSession(context: Context, map: Map<*, *>?) {
        val edit = prefs(context).edit()
        if (map == null) {
            edit.remove(SESSION)
        } else {
            val json = JSONObject()
            for ((k, v) in map) if (k is String && (v is String || v is Number || v is Boolean)) json.put(k, v)
            edit.putString(SESSION, json.toString())
        }
        edit.apply()
    }

    fun clear(context: Context) {
        prefs(context).edit()
            .remove(QUEUE).remove(SESSION).remove(INDEX).remove(POSITION).remove(REPEAT).remove(EXTRAS).remove(RESUMABLE)
            .apply()
    }

    fun load(context: Context): StoredPlayback? {
        val p = prefs(context)
        val raw = p.getString(QUEUE, null) ?: return null
        return try {
            val array = JSONArray(raw)
            val items = (0 until array.length()).map {
                val o = array.getJSONObject(it)
                StoredItem(
                    id = o.optString("id"),
                    uri = o.optString("uri"),
                    title = o.optString("title"),
                    artist = o.optString("artist"),
                    album = o.optString("album"),
                    durationMs = o.optLong("durationMs"),
                    art = if (o.isNull("art")) null else o.optString("art"),
                )
            }
            if (items.isEmpty()) return null
            val session = p.getString(SESSION, null)?.let { s ->
                val o = JSONObject(s)
                o.keys().asSequence().associateWith { k -> o.get(k) as Any? }
            }
            StoredPlayback(
                items = items,
                index = p.getInt(INDEX, 0).coerceIn(0, items.size - 1),
                positionMs = p.getLong(POSITION, 0L).coerceAtLeast(0L),
                repeat = p.getString(REPEAT, "off") ?: "off",
                extras = p.getString(EXTRAS, "") ?: "",
                session = session,
                resumable = p.getBoolean(RESUMABLE, false),
            )
        } catch (_: Exception) {
            null
        }
    }

    // ── 재생 속도 (앱 없이 프로세스가 새로 떠도 같은 속도로 이어 재생하려고 보관) ──

    fun speed(context: Context) = prefs(context).getFloat(SPEED, 1f)

    fun saveSpeed(context: Context, value: Float) {
        prefs(context).edit().putFloat(SPEED, value).apply()
    }

    // ── 출력 기기 동작 설정 (앱 없이도 지켜야 해서 네이티브에도 보관) ──

    fun pauseOnDisconnect(context: Context) = prefs(context).getBoolean(PAUSE_ON_DISCONNECT, true)

    fun resumeOnConnect(context: Context) = prefs(context).getBoolean(RESUME_ON_CONNECT, false)

    /** 알림을 지운 뒤나 재생이 끝난 뒤에도 블루투스 버튼으로 이어 재생할지 (기본 꺼짐). */
    fun resumeWithoutNotification(context: Context) = prefs(context).getBoolean(RESUME_WITHOUT_NOTIFICATION, true)

    fun setResumeWithoutNotification(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean(RESUME_WITHOUT_NOTIFICATION, value).apply()
    }

    fun saveOutputBehavior(context: Context, pauseOnDisconnect: Boolean, resumeOnConnect: Boolean) {
        prefs(context).edit()
            .putBoolean(PAUSE_ON_DISCONNECT, pauseOnDisconnect)
            .putBoolean(RESUME_ON_CONNECT, resumeOnConnect)
            .apply()
    }
}
