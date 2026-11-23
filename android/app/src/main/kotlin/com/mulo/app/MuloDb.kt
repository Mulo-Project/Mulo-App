package com.mulo.app

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.util.concurrent.CopyOnWriteArrayList

/**
 * 앱 로컬 DB (SQLite 파일 `music_app.sqlite`)의 유일한 주인. 열기 · 만들기 · 버전 올리기 · 바뀜 알림을 맡고,
 * 읽고 쓰는 일은 [LibraryDb]가 한다. Dart는 이 DB를 열지 않는다 (채널 `music_app/db`로 부르기만 한다).
 *
 * 파일은 예전에 drift가 만들던 것과 같은 위치 · 같은 열 이름 · 같은 버전(13)이라 설치된 앱의 데이터가 그대로 이어진다.
 * 시각 열은 drift 기본대로 초 단위 정수(unix seconds), 참 · 거짓은 0 · 1.
 */
object MuloDb {
    const val VERSION = 13

    const val TRACKS = "tracks"
    const val COVERS = "covers"
    const val COVER_COLORS = "cover_colors"
    const val LYRICS_FILES = "lyrics_files"
    const val PLAYS = "plays"
    const val PLAYLISTS = "playlists"
    const val PLAYLIST_TRACKS = "playlist_tracks"

    private var db: SQLiteDatabase? = null

    /** drift_flutter가 열던 파일 (`getApplicationDocumentsDirectory()/music_app.sqlite`, Android는 `app_flutter`). */
    private fun file(context: Context) =
        File(context.getDir("flutter", Context.MODE_PRIVATE), "music_app.sqlite")

    @Synchronized
    fun get(context: Context): SQLiteDatabase {
        db?.let { if (it.isOpen) return it }
        val opened = SQLiteDatabase.openOrCreateDatabase(file(context), null)
        opened.enableWriteAheadLogging()
        prepare(opened)
        db = opened
        return opened
    }

    // ---- 바뀜 알림: 화면이 목록을 다시 읽게 한다 ----

    /** 테이블이 바뀔 때 부른다 (바뀐 테이블 이름들). */
    private val listeners = CopyOnWriteArrayList<(Set<String>) -> Unit>()

    fun addListener(l: (Set<String>) -> Unit) {
        listeners.add(l)
    }

    fun removeListener(l: (Set<String>) -> Unit) {
        listeners.remove(l)
    }

    fun changed(vararg tables: String) {
        val set = tables.toSet()
        for (l in listeners) l(set)
    }

    /** 한 번에 묶어 쓰고, 끝나면 [tables] 바뀜을 알린다. 중간에 예외가 나면 되돌린다. */
    fun <T> write(context: Context, vararg tables: String, block: (SQLiteDatabase) -> T): T {
        val d = get(context)
        d.beginTransaction()
        val value = try {
            val v = block(d)
            d.setTransactionSuccessful()
            v
        } finally {
            d.endTransaction()
        }
        if (tables.isNotEmpty()) changed(*tables)
        return value
    }

    // ---- 만들기 · 버전 올리기 ----

    private fun prepare(d: SQLiteDatabase) {
        val old = d.version
        d.beginTransaction()
        try {
            when {
                old == 0 -> createAll(d)
                old < VERSION -> upgrade(d, old)
            }
            // 이미 최신 버전인데 열이 빠진 DB도 고친다 (빌드를 번갈아 설치하는 등).
            repairColumns(d)
            d.version = VERSION
            d.setTransactionSuccessful()
        } finally {
            d.endTransaction()
        }
    }

    private fun createAll(d: SQLiteDatabase) {
        d.execSQL(
            "CREATE TABLE IF NOT EXISTS tracks (" +
                "id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL, album TEXT NOT NULL, " +
                "genre TEXT NOT NULL DEFAULT '', duration_ms INTEGER NOT NULL, uri TEXT NOT NULL UNIQUE, " +
                "folder TEXT NOT NULL DEFAULT '', source TEXT NOT NULL, added_at INTEGER NOT NULL, " +
                "hidden INTEGER NOT NULL DEFAULT 0, mime TEXT NOT NULL DEFAULT '')",
        )
        d.execSQL(
            "CREATE TABLE IF NOT EXISTS covers (" +
                "key TEXT NOT NULL PRIMARY KEY, path TEXT NOT NULL, url TEXT, scale REAL NOT NULL DEFAULT 1, " +
                "dx REAL NOT NULL DEFAULT 0, dy REAL NOT NULL DEFAULT 0, rotation REAL NOT NULL DEFAULT 0)",
        )
        d.execSQL("CREATE TABLE IF NOT EXISTS cover_colors (key TEXT NOT NULL PRIMARY KEY, color INTEGER NOT NULL)")
        d.execSQL("CREATE TABLE IF NOT EXISTS lyrics_files (track_id TEXT NOT NULL PRIMARY KEY, path TEXT NOT NULL)")
        d.execSQL(
            "CREATE TABLE IF NOT EXISTS plays (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, track_id TEXT NOT NULL, played_at INTEGER NOT NULL, " +
                "listened_ms INTEGER NOT NULL DEFAULT 0)",
        )
        d.execSQL(
            "CREATE TABLE IF NOT EXISTS playlists (" +
                "id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, created_at INTEGER NOT NULL, " +
                "sort_order INTEGER NOT NULL DEFAULT 0)",
        )
        d.execSQL(
            "CREATE TABLE IF NOT EXISTS playlist_tracks (" +
                "playlist_id TEXT NOT NULL, track_id TEXT NOT NULL, added_at INTEGER NOT NULL, " +
                "PRIMARY KEY (playlist_id, track_id))",
        )
    }

    /** 옛 버전(drift 시절 스키마 2~12)에서 올린다. 단계마다 drift 마이그레이션과 같은 일을 한다. */
    private fun upgrade(d: SQLiteDatabase, from: Int) {
        // 없는 테이블은 모두 만들고(IF NOT EXISTS), 빠진 열은 아래 repairColumns가 더한다.
        createAll(d)
        // 들은 시간이 기록되지 않던 옛 재생은 곡 길이로 한 번 채운다.
        if (from < 8) {
            d.execSQL(
                "UPDATE plays SET listened_ms = COALESCE(" +
                    "(SELECT duration_ms FROM tracks WHERE tracks.id = plays.track_id), 0) WHERE listened_ms = 0",
            )
        }
        // 영상 모음(MediaStore 영상)에 있는 곡은 한 번 영상으로 표시한다.
        if (from < 13) {
            repairColumns(d)
            d.execSQL("UPDATE tracks SET mime = 'video/*' WHERE uri LIKE 'content://media/external/video/%'")
        }
    }

    /** 있어야 할 열이 없으면 더한다. */
    private fun repairColumns(d: SQLiteDatabase) {
        addColumn(d, "tracks", "genre", "TEXT NOT NULL DEFAULT ''")
        addColumn(d, "tracks", "folder", "TEXT NOT NULL DEFAULT ''")
        addColumn(d, "tracks", "hidden", "INTEGER NOT NULL DEFAULT 0")
        addColumn(d, "tracks", "mime", "TEXT NOT NULL DEFAULT ''")
        addColumn(d, "covers", "url", "TEXT")
        addColumn(d, "covers", "scale", "REAL NOT NULL DEFAULT 1")
        addColumn(d, "covers", "dx", "REAL NOT NULL DEFAULT 0")
        addColumn(d, "covers", "dy", "REAL NOT NULL DEFAULT 0")
        addColumn(d, "covers", "rotation", "REAL NOT NULL DEFAULT 0")
        addColumn(d, "plays", "listened_ms", "INTEGER NOT NULL DEFAULT 0")
        addColumn(d, "playlists", "sort_order", "INTEGER NOT NULL DEFAULT 0")
    }

    private fun addColumn(d: SQLiteDatabase, table: String, column: String, definition: String) {
        val exists = d.rawQuery("PRAGMA table_info($table)", null).use { c ->
            val nameIndex = c.getColumnIndexOrThrow("name")
            var found = false
            while (c.moveToNext()) if (c.getString(nameIndex) == column) found = true
            found
        }
        if (!exists) d.execSQL("ALTER TABLE $table ADD COLUMN $column $definition")
    }
}
