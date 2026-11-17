package com.mulo.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * 받은 곡을 보관함에 넣는 데 필요한 모든 것 (곡 · 재생목록 · 커버 · 색 · 가사). 보관함 DB(drift)는 Dart가 쥐므로
 * 네이티브는 파일 저장까지 하고 이 값을 Dart에 넘긴다 (`registered` 이벤트). Dart가 등록하고 `ack`로 알려 줄 때까지
 * [Pending]에 남겨 두어, 앱이 꺼져 있었거나 등록 중에 끊겨도 다음에 다시 넘긴다.
 */
object AppDb {
    class Registration(
        val trackId: String,
        val title: String,
        val artist: String,
        val album: String,
        val genre: String,
        val durationMs: Long,
        val uri: String,
        val folder: String,
        val mime: String,
        val addedAtSec: Long,
        val playlistIds: List<String>,
        /** 커버: `url` 또는 `path`(앱 폴더로 복사 끝난 파일)와 확대 · 위치 · 각도. 없으면 null. */
        val cover: JSONObject?,
        val color: Long?,
        /** 앱 폴더에 쓴 가사 파일 경로 (없으면 null). */
        val lyricsPath: String?,
    ) {
        fun toJson() = JSONObject()
            .put("trackId", trackId).put("title", title).put("artist", artist).put("album", album)
            .put("genre", genre).put("durationMs", durationMs).put("uri", uri).put("folder", folder)
            .put("mime", mime).put("addedAtSec", addedAtSec).put("playlistIds", JSONArray(playlistIds))
            .put("cover", cover).put("color", color).put("lyricsPath", lyricsPath)

        companion object {
            fun fromJson(j: JSONObject) = Registration(
                j.getString("trackId"), j.getString("title"), j.getString("artist"), j.getString("album"),
                j.getString("genre"), j.getLong("durationMs"), j.getString("uri"), j.getString("folder"),
                j.getString("mime"), j.getLong("addedAtSec"),
                List(j.getJSONArray("playlistIds").length()) { j.getJSONArray("playlistIds").getString(it) },
                j.optJSONObject("cover"), if (j.isNull("color")) null else j.getLong("color"),
                if (j.isNull("lyricsPath")) null else j.getString("lyricsPath"),
            )
        }
    }

    /** Dart가 등록했다고 알려 주기 전의 등록들 (앱 폴더의 `pending_register.json`). */
    class Pending(context: Context) {
        private val store = File(context.filesDir, "pending_register.json")

        @Synchronized
        fun add(r: Registration) {
            val list = read()
            list.put(r.toJson())
            store.writeText(list.toString())
        }

        /** Dart가 등록을 끝냈다. */
        @Synchronized
        fun remove(trackId: String) {
            val list = read()
            val kept = JSONArray()
            for (i in 0 until list.length()) {
                val o = list.getJSONObject(i)
                if (o.optString("trackId") != trackId) kept.put(o)
            }
            if (kept.length() == 0) store.delete() else store.writeText(kept.toString())
        }

        /** 아직 등록이 끝나지 않은 곡들. */
        @Synchronized
        fun all(): List<JSONObject> {
            val list = read()
            return List(list.length()) { list.getJSONObject(it) }
        }

        private fun read(): JSONArray = try {
            if (store.exists()) JSONArray(store.readText()) else JSONArray()
        } catch (e: Exception) {
            JSONArray()
        }
    }
}
