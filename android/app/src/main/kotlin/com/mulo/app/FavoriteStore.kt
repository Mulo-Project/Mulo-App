package com.mulo.app

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File

/**
 * 좋아요를 앱(Dart)이 없을 때 네이티브가 직접 읽고 쓴다. 알림의 좋아요 버튼이 앱 없이도 동작하게 하려는 것이다.
 *
 * 좋아요는 앱 DB(drift · SQLite)의 `playlist_tracks`에 `playlist_id = 'favorites'`인 줄이 있느냐로 정해진다
 * (Dart의 `Playlist.favoritesId`, `DriftPlaylistRepository`와 같은 규칙). 시각 열은 drift 기본대로 초 단위 정수.
 * 앱 DB 파일이 아직 없으면 만들지 않고 아무것도 하지 않는다.
 * Dart가 붙어 있을 때는 drift의 실시간 목록이 이 쓰기를 모르므로 쓰지 않고 Dart에 맡긴다 ([PlaybackHub] 참고).
 */
object FavoriteStore {
    private const val FAVORITES_ID = "favorites"

    /** drift_flutter가 연 DB 파일 (`getApplicationDocumentsDirectory()/music_app.sqlite`, Android는 `app_flutter`). */
    private fun dbFile(context: Context) =
        File(context.getDir("flutter", Context.MODE_PRIVATE), "music_app.sqlite")

    private fun <T> withDb(context: Context, write: Boolean, block: (SQLiteDatabase) -> T): T? {
        val file = dbFile(context)
        if (!file.exists()) return null
        return try {
            val flags = if (write) SQLiteDatabase.OPEN_READWRITE else SQLiteDatabase.OPEN_READONLY
            SQLiteDatabase.openDatabase(file.path, null, flags).use(block)
        } catch (_: Exception) {
            null
        }
    }

    private fun exists(db: SQLiteDatabase, trackId: String): Boolean =
        db.rawQuery(
            "SELECT 1 FROM playlist_tracks WHERE playlist_id = ? AND track_id = ? LIMIT 1",
            arrayOf(FAVORITES_ID, trackId),
        ).use { it.moveToFirst() }

    /** 좋아요한 곡인지. DB를 읽지 못하면 null. */
    fun isFavorite(context: Context, trackId: String): Boolean? {
        if (trackId.isEmpty()) return null
        return withDb(context, write = false) { exists(it, trackId) }
    }

    /** 좋아요를 켜고 끈다. 바뀐 뒤의 상태를 돌려주고, DB를 쓰지 못하면 null. */
    fun toggle(context: Context, trackId: String): Boolean? {
        if (trackId.isEmpty()) return null
        return withDb(context, write = true) { db ->
            db.beginTransaction()
            try {
                val now = if (exists(db, trackId)) {
                    db.delete("playlist_tracks", "playlist_id = ? AND track_id = ?", arrayOf(FAVORITES_ID, trackId))
                    false
                } else {
                    db.execSQL(
                        "INSERT OR IGNORE INTO playlist_tracks (playlist_id, track_id, added_at) VALUES (?, ?, ?)",
                        arrayOf<Any>(FAVORITES_ID, trackId, System.currentTimeMillis() / 1000),
                    )
                    true
                }
                db.setTransactionSuccessful()
                now
            } finally {
                db.endTransaction()
            }
        }
    }
}
