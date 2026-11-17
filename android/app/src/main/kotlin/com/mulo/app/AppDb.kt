package com.mulo.app

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * 앱 DB(drift가 만든 SQLite 파일 `music_app.sqlite`)에 받은 곡을 직접 쓴다. 스키마 · 마이그레이션의 주인은 Dart(drift)이고,
 * 여기서는 Dart가 한 번 열어 최신 스키마가 된 파일에만 행을 더한다. 파일이 없거나 버전이 낮으면 쓰지 못하고(null),
 * 호출한 쪽이 결과를 [Pending]에 맡겨 두었다가 앱이 DB를 연 뒤([flush]) 등록한다.
 * 날짜 칸은 drift 기본대로 유닉스 초(정수)다.
 */
object AppDb {
    /** drift `schemaVersion` (lib/core/database/app_database.dart). 이보다 낮으면 쓰지 않는다. */
    private const val MIN_VERSION = 13

    private fun file(context: Context) = File(context.dataDir, "app_flutter/music_app.sqlite")

    /** 쓸 수 있으면 열린 DB, 아니면 null. 쓴 뒤 [SQLiteDatabase.close]는 부르는 쪽이 한다. */
    fun open(context: Context): SQLiteDatabase? {
        val f = file(context)
        if (!f.exists()) return null
        return try {
            val db = SQLiteDatabase.openDatabase(f.path, null, SQLiteDatabase.OPEN_READWRITE)
            if (db.version < MIN_VERSION) {
                db.close()
                return null
            }
            // 앱(Dart)과 같은 파일을 같이 열므로 잠겨 있으면 잠시 기다린다.
            db.rawQuery("PRAGMA busy_timeout = 8000", null).use { it.moveToFirst() }
            db
        } catch (e: Exception) {
            MuloLog.e(MuloLog.NATIVE, "DB 열기 실패: ${e.message}", e)
            null
        }
    }

    /** 곡 하나를 보관함에 넣는 데 필요한 모든 것 (곡 · 재생목록 · 커버 · 색 · 가사). JSON으로 맡겨 둘 수 있다. */
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

    /** [r]을 한 번에(트랜잭션) 쓴다. 이미 있는 곡(같은 주소)은 그대로 두고 숨김만 푼다. */
    fun register(db: SQLiteDatabase, r: Registration) {
        db.beginTransaction()
        try {
            val track = ContentValues().apply {
                put("id", r.trackId); put("title", r.title); put("artist", r.artist); put("album", r.album)
                put("genre", r.genre); put("duration_ms", r.durationMs); put("uri", r.uri)
                put("folder", r.folder); put("source", "download"); put("added_at", r.addedAtSec)
                put("hidden", 0); put("mime", r.mime)
            }
            db.insertWithOnConflict("tracks", null, track, SQLiteDatabase.CONFLICT_IGNORE)
            db.execSQL("UPDATE tracks SET hidden = 0 WHERE uri = ? AND hidden = 1", arrayOf(r.uri))
            for ((i, p) in r.playlistIds.withIndex()) {
                val row = ContentValues().apply {
                    put("playlist_id", p); put("track_id", r.trackId); put("added_at", r.addedAtSec + i)
                }
                db.insertWithOnConflict("playlist_tracks", null, row, SQLiteDatabase.CONFLICT_IGNORE)
            }
            r.cover?.let { c ->
                val row = ContentValues().apply {
                    put("key", "track:${r.trackId}")
                    put("path", c.optString("path", ""))
                    if (c.has("url") && !c.isNull("url")) put("url", c.getString("url")) else putNull("url")
                    put("scale", c.optDouble("scale", 1.0)); put("dx", c.optDouble("dx", 0.0))
                    put("dy", c.optDouble("dy", 0.0)); put("rotation", c.optDouble("rotation", 0.0))
                }
                db.insertWithOnConflict("covers", null, row, SQLiteDatabase.CONFLICT_REPLACE)
            }
            r.color?.let {
                val row = ContentValues().apply { put("key", "track:${r.trackId}"); put("color", it) }
                db.insertWithOnConflict("cover_colors", null, row, SQLiteDatabase.CONFLICT_REPLACE)
            }
            r.lyricsPath?.let {
                val row = ContentValues().apply { put("track_id", r.trackId); put("path", it) }
                db.insertWithOnConflict("lyrics_files", null, row, SQLiteDatabase.CONFLICT_REPLACE)
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    /** DB를 아직 못 쓸 때 맡겨 둔 등록들 (앱 폴더의 `pending_register.json`). */
    class Pending(private val context: Context) {
        private val store = File(context.filesDir, "pending_register.json")

        @Synchronized
        fun add(r: Registration) {
            val list = read()
            list.put(r.toJson())
            store.writeText(list.toString())
        }

        /** 맡겨 둔 등록을 쓸 수 있으면 모두 쓰고 비운다. 쓴 곡 수를 돌려준다 (못 쓰면 0). */
        @Synchronized
        fun flush(): Int {
            val list = read()
            if (list.length() == 0) return 0
            val db = open(context) ?: return 0
            var done = 0
            try {
                for (i in 0 until list.length()) {
                    try {
                        register(db, Registration.fromJson(list.getJSONObject(i)))
                        done++
                    } catch (e: Exception) {
                        MuloLog.e(MuloLog.NATIVE, "맡겨 둔 등록 실패: ${e.message}", e)
                    }
                }
            } finally {
                db.close()
            }
            store.delete()
            return done
        }

        private fun read(): JSONArray = try {
            if (store.exists()) JSONArray(store.readText()) else JSONArray()
        } catch (e: Exception) {
            JSONArray()
        }
    }
}
