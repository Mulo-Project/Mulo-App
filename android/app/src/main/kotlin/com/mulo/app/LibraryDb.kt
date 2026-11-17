package com.mulo.app

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import java.io.File

/**
 * 앱 DB의 모든 읽기 · 쓰기 (곡 · 커버 · 커버 색 · 가사 · 재생 기록 · 재생목록). 값은 Dart가 정해서 넘기고
 * 규칙(숨김 풀기 · 정렬 · 곡 수 · 지울 때 함께 지울 것 · 앱 폴더 파일 정리)은 여기가 가진다.
 * 결과는 채널로 보내기 쉬운 Map · List다 ([DbChannel]).
 */
class LibraryDb(private val context: Context) {
    private val db get() = MuloDb.get(context)

    private fun nowSec() = System.currentTimeMillis() / 1000

    // ---------------- 곡 ----------------

    private fun trackMap(c: Cursor) = mapOf(
        "id" to c.str("id"), "title" to c.str("title"), "artist" to c.str("artist"), "album" to c.str("album"),
        "genre" to c.str("genre"), "durationMs" to c.long("duration_ms"), "uri" to c.str("uri"),
        "folder" to c.str("folder"), "source" to c.str("source"), "addedAtSec" to c.long("added_at"),
        "mime" to c.str("mime"),
    )

    /** 보이는 곡 (숨기지 않은 곡), 추가일 최신순. */
    fun tracks(): List<Map<String, Any?>> =
        db.rawQuery("SELECT * FROM tracks WHERE hidden = 0 ORDER BY added_at DESC", null).use { c ->
            buildList { while (c.moveToNext()) add(trackMap(c)) }
        }

    private fun visibleCount(d: SQLiteDatabase): Long =
        d.rawQuery("SELECT COUNT(*) FROM tracks WHERE hidden = 0", null).use { if (it.moveToFirst()) it.getLong(0) else 0L }

    /** 곡을 추가한다. 같은 재생 주소(uri)가 이미 있으면 건너뛴다. 새로 보이게 된 수를 돌려준다. */
    fun addTracks(items: List<Map<String, Any?>>): Int {
        if (items.isEmpty()) return 0
        var added = 0
        MuloDb.write(context, MuloDb.TRACKS) { d ->
            val before = visibleCount(d)
            for (t in items) {
                val uri = t["uri"] as String
                val source = t["source"] as String
                val folder = (t["folder"] as? String) ?: ""
                val addedAt = (t["addedAtSec"] as Number).toLong()
                d.insertWithOnConflict("tracks", null, trackValues(t), SQLiteDatabase.CONFLICT_IGNORE)
                // 폴더를 빼서 숨겨 둔 곡은 다시 찾으면 숨김만 푼다 (기록은 그대로).
                d.execSQL("UPDATE tracks SET hidden = 0 WHERE uri = ? AND hidden = 1", arrayOf(uri))
                // 기기에서 불러온 곡은 다시 찾을 때마다 파일 날짜로 추가일을 맞춘다.
                if (source == "device") {
                    d.execSQL("UPDATE tracks SET added_at = ? WHERE uri = ? AND source = 'device'", arrayOf<Any>(addedAt, uri))
                }
                // 폴더 칸이 생기기 전에 넣은 곡은 다시 찾을 때 폴더를 채운다.
                if (folder.isNotEmpty()) {
                    d.execSQL("UPDATE tracks SET folder = ? WHERE uri = ? AND folder = ''", arrayOf(folder, uri))
                }
            }
            added = (visibleCount(d) - before).toInt()
        }
        return added
    }

    private fun trackValues(t: Map<String, Any?>) = ContentValues().apply {
        put("id", t["id"] as String)
        put("title", t["title"] as String)
        put("artist", t["artist"] as String)
        put("album", t["album"] as String)
        put("genre", (t["genre"] as? String) ?: "")
        put("duration_ms", (t["durationMs"] as Number).toLong())
        put("uri", t["uri"] as String)
        put("folder", (t["folder"] as? String) ?: "")
        put("source", t["source"] as String)
        put("added_at", (t["addedAtSec"] as Number).toLong())
        put("mime", (t["mime"] as? String) ?: "")
    }

    /** 제목 · 아티스트 · 앨범 · 장르를 바꾼다. 곡이 없으면 false. */
    fun updateInfo(id: String, title: String, artist: String, album: String, genre: String): Boolean {
        var changed = 0
        MuloDb.write(context, MuloDb.TRACKS) { d ->
            val v = ContentValues().apply { put("title", title); put("artist", artist); put("album", album); put("genre", genre) }
            changed = d.update("tracks", v, "id = ?", arrayOf(id))
        }
        return changed > 0
    }

    /** 곡을 보관함에서 숨긴다. 재생 기록 · 재생목록 · 커버는 남긴다. */
    fun hide(id: String) {
        MuloDb.write(context, MuloDb.TRACKS) { d ->
            d.update("tracks", ContentValues().apply { put("hidden", 1) }, "id = ?", arrayOf(id))
        }
    }

    /** 곡 여러 개를 한 번에 숨긴다 (한 번의 쓰기 · 한 번의 바뀜 알림). */
    fun hideMany(ids: List<String>) {
        if (ids.isEmpty()) return
        MuloDb.write(context, MuloDb.TRACKS) { d ->
            val v = ContentValues().apply { put("hidden", 1) }
            for (id in ids) d.update("tracks", v, "id = ?", arrayOf(id))
        }
    }

    fun hiddenCount(): Int =
        db.rawQuery("SELECT COUNT(*) FROM tracks WHERE hidden = 1", null).use { if (it.moveToFirst()) it.getInt(0) else 0 }

    /** 숨긴 곡과 곡마다 남은 기록. 제목순. */
    fun hiddenTracks(): List<Map<String, Any?>> {
        val rows = db.rawQuery("SELECT * FROM tracks WHERE hidden = 1 ORDER BY title ASC", null).use { c ->
            buildList { while (c.moveToNext()) add(trackMap(c)) }
        }
        return rows.map { t ->
            val id = t["id"] as String
            val (count, last) = db.rawQuery(
                "SELECT COUNT(*), MAX(played_at) FROM plays WHERE track_id = ?", arrayOf(id),
            ).use { c -> c.moveToFirst(); c.getLong(0) to (if (c.isNull(1)) null else c.getLong(1)) }
            val inPlaylists = db.rawQuery(
                "SELECT COUNT(*) FROM playlist_tracks WHERE track_id = ?", arrayOf(id),
            ).use { c -> c.moveToFirst(); c.getInt(0) }
            val hasCover = exists("SELECT 1 FROM covers WHERE key = ?", "track:$id")
            val hasLyrics = exists("SELECT 1 FROM lyrics_files WHERE track_id = ?", id)
            mapOf(
                "track" to t, "playCount" to count, "lastPlayedAtSec" to last, "playlistCount" to inPlaylists,
                "hasCover" to hasCover, "hasLyrics" to hasLyrics,
            )
        }
    }

    private fun exists(sql: String, arg: String): Boolean = db.rawQuery("$sql LIMIT 1", arrayOf(arg)).use { it.moveToFirst() }

    /**
     * 숨긴 곡의 행과 재생 기록 · 재생목록 소속 · 커버 · 커버 색 · 가사 연결을 지운다 (앱 폴더에 복사한 커버 · 가사 파일도).
     * [ids]가 있으면 그 중 숨긴 곡만, null이면 모두. 보이는 곡은 건드리지 않는다. 지운 곡 수를 돌려준다.
     */
    fun purgeHidden(ids: List<String>?, emptyOnly: Boolean = false): Int {
        if (ids != null && ids.isEmpty()) return 0
        val files = mutableListOf<String>()
        var purged = 0
        MuloDb.write(
            context, MuloDb.TRACKS, MuloDb.COVERS, MuloDb.COVER_COLORS, MuloDb.LYRICS_FILES,
            MuloDb.PLAYLIST_TRACKS, MuloDb.PLAYS,
        ) { d ->
            val target = d.rawQuery("SELECT id FROM tracks WHERE hidden = 1", null).use { c ->
                buildList { while (c.moveToNext()) add(c.getString(0)) }
            }.filter { ids == null || it in ids }.filter { !emptyOnly || !hasRecords(d, it) }
            for (id in target) {
                val key = "track:$id"
                d.rawQuery("SELECT path FROM covers WHERE key = ?", arrayOf(key)).use { c ->
                    if (c.moveToFirst() && c.getString(0).isNotEmpty()) files.add(c.getString(0))
                }
                d.rawQuery("SELECT path FROM lyrics_files WHERE track_id = ?", arrayOf(id)).use { c ->
                    if (c.moveToFirst()) files.add(c.getString(0))
                }
                d.delete("covers", "key = ?", arrayOf(key))
                d.delete("cover_colors", "key = ?", arrayOf(key))
                d.delete("lyrics_files", "track_id = ?", arrayOf(id))
                d.delete("playlist_tracks", "track_id = ?", arrayOf(id))
                d.delete("plays", "track_id = ?", arrayOf(id))
                d.delete("tracks", "id = ?", arrayOf(id))
            }
            purged = target.size
        }
        files.forEach(::deleteQuietly)
        return purged
    }

    /** 곡에 남은 기록(재생 · 재생목록 · 커버 · 가사)이 하나라도 있는지. */
    private fun hasRecords(d: SQLiteDatabase, id: String): Boolean {
        fun has(sql: String, arg: String) = d.rawQuery("$sql LIMIT 1", arrayOf(arg)).use { it.moveToFirst() }
        return has("SELECT 1 FROM plays WHERE track_id = ?", id) ||
            has("SELECT 1 FROM playlist_tracks WHERE track_id = ?", id) ||
            has("SELECT 1 FROM covers WHERE key = ?", "track:$id") ||
            has("SELECT 1 FROM lyrics_files WHERE track_id = ?", id)
    }

    /** 곡을 보관함에서 지운다. 재생목록 · 재생 기록 · 커버 기록도 함께 지운다 (음악 파일은 건드리지 않는다). */
    fun deleteTrack(id: String) {
        MuloDb.write(context, MuloDb.TRACKS, MuloDb.PLAYLIST_TRACKS, MuloDb.PLAYS, MuloDb.COVERS) { d ->
            d.delete("tracks", "id = ?", arrayOf(id))
            d.delete("playlist_tracks", "track_id = ?", arrayOf(id))
            d.delete("plays", "track_id = ?", arrayOf(id))
            d.delete("covers", "key = ?", arrayOf("track:$id"))
        }
    }

    // ---------------- 커버 ----------------

    /** 모든 커버. 파일이 사라진 기기 사진은 건너뛴다. */
    fun covers(): List<Map<String, Any?>> =
        db.rawQuery("SELECT key, path, url, scale, dx, dy, rotation FROM covers", null).use { c ->
            buildList {
                while (c.moveToNext()) {
                    val url = if (c.isNull(2)) null else c.getString(2)
                    val path = c.getString(1)
                    if (url == null && !File(path).exists()) continue
                    add(
                        mapOf(
                            "key" to c.getString(0), "path" to path, "url" to url,
                            "scale" to c.getDouble(3), "dx" to c.getDouble(4), "dy" to c.getDouble(5),
                            "rotation" to c.getDouble(6),
                        ),
                    )
                }
            }
        }

    /** 커버를 넣거나 바꾼다. 앱 폴더에 있던 옛 이미지 파일은 지운다 (새 [path]와 다를 때). */
    fun saveCover(key: String, path: String, url: String?, scale: Double, dx: Double, dy: Double, rotation: Double) {
        val old = coverPath(key)
        MuloDb.write(context, MuloDb.COVERS) { d ->
            val v = ContentValues().apply {
                put("key", key); put("path", path); put("url", url)
                put("scale", scale); put("dx", dx); put("dy", dy); put("rotation", rotation)
            }
            d.insertWithOnConflict("covers", null, v, SQLiteDatabase.CONFLICT_REPLACE)
        }
        if (old != null && old != path) deleteQuietly(old)
    }

    fun saveCoverTransform(key: String, scale: Double, dx: Double, dy: Double, rotation: Double) {
        MuloDb.write(context, MuloDb.COVERS) { d ->
            val v = ContentValues().apply { put("scale", scale); put("dx", dx); put("dy", dy); put("rotation", rotation) }
            d.update("covers", v, "key = ?", arrayOf(key))
        }
    }

    fun removeCover(key: String) {
        val old = coverPath(key)
        MuloDb.write(context, MuloDb.COVERS) { d -> d.delete("covers", "key = ?", arrayOf(key)) }
        if (old != null) deleteQuietly(old)
    }

    /** 앱 폴더에 복사해 둔 파일 경로 (웹 이미지면 null). */
    private fun coverPath(key: String): String? =
        db.rawQuery("SELECT path FROM covers WHERE key = ?", arrayOf(key)).use { c ->
            if (c.moveToFirst()) c.getString(0).ifEmpty { null } else null
        }

    // ---------------- 커버 색 ----------------

    fun coverColors(): Map<String, Long> =
        db.rawQuery("SELECT key, color FROM cover_colors", null).use { c ->
            buildMap { while (c.moveToNext()) put(c.getString(0), c.getLong(1)) }
        }

    fun saveCoverColor(key: String, color: Long) {
        MuloDb.write(context, MuloDb.COVER_COLORS) { d ->
            d.insertWithOnConflict(
                "cover_colors", null, ContentValues().apply { put("key", key); put("color", color) },
                SQLiteDatabase.CONFLICT_REPLACE,
            )
        }
    }

    fun removeCoverColor(key: String) {
        MuloDb.write(context, MuloDb.COVER_COLORS) { d -> d.delete("cover_colors", "key = ?", arrayOf(key)) }
    }

    // ---------------- 가사 ----------------

    /** 곡에 저장된 가사 파일 경로. 없으면 null. */
    fun lyricsPath(trackId: String): String? =
        db.rawQuery("SELECT path FROM lyrics_files WHERE track_id = ?", arrayOf(trackId)).use {
            if (it.moveToFirst()) it.getString(0) else null
        }

    /** 가사 파일 경로를 저장한다. 싱크 ↔ 일반 글로 바뀌어 경로가 달라지면 옛 파일을 지운다. */
    fun saveLyricsPath(trackId: String, path: String) {
        val old = lyricsPath(trackId)
        MuloDb.write(context, MuloDb.LYRICS_FILES) { d ->
            d.insertWithOnConflict(
                "lyrics_files", null, ContentValues().apply { put("track_id", trackId); put("path", path) },
                SQLiteDatabase.CONFLICT_REPLACE,
            )
        }
        if (old != null && old != path) deleteQuietly(old)
    }

    fun removeLyrics(trackId: String) {
        val old = lyricsPath(trackId)
        MuloDb.write(context, MuloDb.LYRICS_FILES) { d -> d.delete("lyrics_files", "track_id = ?", arrayOf(trackId)) }
        if (old != null) deleteQuietly(old)
    }

    // ---------------- 재생 기록 ----------------

    /** 재생을 한 줄 남기고 그 id를 돌려준다. */
    fun recordPlay(trackId: String, playedAtSec: Long, listenedMs: Long): Long {
        var id = -1L
        MuloDb.write(context, MuloDb.PLAYS) { d ->
            id = d.insert(
                "plays", null,
                ContentValues().apply { put("track_id", trackId); put("played_at", playedAtSec); put("listened_ms", listenedMs) },
            )
        }
        return id
    }

    fun updateListened(id: Long, listenedMs: Long) {
        MuloDb.write(context, MuloDb.PLAYS) { d ->
            d.update("plays", ContentValues().apply { put("listened_ms", listenedMs) }, "id = ?", arrayOf(id.toString()))
        }
    }

    /** 재생 기록, 최근 것부터. */
    fun plays(): List<Map<String, Any?>> =
        db.rawQuery("SELECT track_id, played_at, listened_ms FROM plays ORDER BY played_at DESC, id DESC", null).use { c ->
            buildList {
                while (c.moveToNext()) add(mapOf("trackId" to c.getString(0), "playedAtSec" to c.getLong(1), "listenedMs" to c.getLong(2)))
            }
        }

    // ---------------- 재생목록 ----------------

    /** 담은 순서. 시각은 초 단위라 같은 초에 담은 곡끼리는 넣은 순서(rowid)로 가린다. */
    private val insertOrder = "added_at ASC, playlist_tracks.rowid ASC"

    /**
     * 즐겨찾기(`favorites`)를 맨 앞에 두고, 사용자가 정한 순서(같으면 만든 순서)로 재생목록을 돌려준다.
     * 곡 수는 보관함에 없는 곡도 담은 기록 그대로 세고, 대표 곡은 많이 들은 곡(없으면 가장 먼저 담은 곡)이다.
     */
    fun playlists(): List<Map<String, Any?>> {
        val d = db
        val lists = d.rawQuery("SELECT id, name FROM playlists ORDER BY sort_order ASC, created_at ASC", null).use { c ->
            buildList { while (c.moveToNext()) add(c.getString(0) to c.getString(1)) }
        }
        val members = linkedMapOf<String, MutableList<String>>()
        d.rawQuery("SELECT playlist_id, track_id FROM playlist_tracks ORDER BY $insertOrder", null).use { c ->
            while (c.moveToNext()) members.getOrPut(c.getString(0)) { mutableListOf() }.add(c.getString(1))
        }
        val visible = HashMap<String, Map<String, String>>()
        d.rawQuery("SELECT id, title, artist, genre FROM tracks WHERE hidden = 0", null).use { c ->
            while (c.moveToNext()) {
                visible[c.getString(0)] = mapOf(
                    "id" to c.getString(0), "title" to c.getString(1), "artist" to c.getString(2), "genre" to c.getString(3),
                )
            }
        }
        val plays = HashMap<String, Int>()
        d.rawQuery("SELECT track_id, COUNT(*) FROM plays GROUP BY track_id", null).use { c ->
            while (c.moveToNext()) plays[c.getString(0)] = c.getInt(1)
        }

        fun build(id: String, name: String): Map<String, Any?> {
            val ids = members[id] ?: emptyList<String>()
            val shown = ids.mapNotNull { visible[it] }
            var best: Map<String, String>? = shown.firstOrNull()
            for (t in shown) if ((plays[t["id"]] ?: 0) > (plays[best!!["id"]] ?: 0)) best = t
            return mapOf("id" to id, "name" to name, "trackCount" to ids.size, "featured" to best, "trackIds" to ids)
        }
        return listOf(build(FAVORITES_ID, "")) + lists.map { (id, name) -> build(id, name) }
    }

    /** 재생목록의 보이는 곡, 담은 순서. */
    fun playlistTracks(playlistId: String): List<Map<String, Any?>> =
        db.rawQuery(
            "SELECT tracks.* FROM playlist_tracks INNER JOIN tracks ON tracks.id = playlist_tracks.track_id " +
                "WHERE playlist_tracks.playlist_id = ? AND tracks.hidden = 0 ORDER BY $insertOrder",
            arrayOf(playlistId),
        ).use { c -> buildList { while (c.moveToNext()) add(trackMap(c)) } }

    /** 새 재생목록 (순서의 맨 뒤). 만든 id와 이름을 돌려준다. */
    fun createPlaylist(name: String): Map<String, Any?> {
        val id = "pl${System.currentTimeMillis() * 1000 + (System.nanoTime() / 1000) % 1000}"
        MuloDb.write(context, MuloDb.PLAYLISTS) { d ->
            val next = d.rawQuery("SELECT MAX(sort_order) FROM playlists", null).use { c ->
                (if (c.moveToFirst() && !c.isNull(0)) c.getLong(0) else 0L) + 1
            }
            d.insert(
                "playlists", null,
                ContentValues().apply { put("id", id); put("name", name); put("created_at", nowSec()); put("sort_order", next) },
            )
        }
        return mapOf("id" to id, "name" to name)
    }

    /** 카드 순서를 [ids] 순서대로 1부터 매긴다. */
    fun reorderPlaylists(ids: List<String>) {
        MuloDb.write(context, MuloDb.PLAYLISTS) { d ->
            ids.forEachIndexed { i, id ->
                d.update("playlists", ContentValues().apply { put("sort_order", i + 1) }, "id = ?", arrayOf(id))
            }
        }
    }

    fun renamePlaylist(id: String, name: String) {
        MuloDb.write(context, MuloDb.PLAYLISTS) { d ->
            d.update("playlists", ContentValues().apply { put("name", name) }, "id = ?", arrayOf(id))
        }
    }

    fun deletePlaylist(id: String) {
        MuloDb.write(context, MuloDb.PLAYLIST_TRACKS, MuloDb.COVERS, MuloDb.PLAYLISTS) { d ->
            d.delete("playlist_tracks", "playlist_id = ?", arrayOf(id))
            d.delete("covers", "key = ?", arrayOf("playlist:$id"))
            d.delete("playlists", "id = ?", arrayOf(id))
        }
    }

    /** 곡 하나를 여러 재생목록에 담는다 (이미 있으면 건너뛴다). */
    fun addTrackToPlaylists(trackId: String, playlistIds: List<String>) {
        val now = nowSec()
        MuloDb.write(context, MuloDb.PLAYLIST_TRACKS) { d ->
            for (pid in playlistIds) insertMember(d, pid, trackId, now)
        }
    }

    /** 곡 여러 개를 재생목록 하나에 담는다 (주어진 순서대로 담긴다). */
    fun addTracksToPlaylist(trackIds: List<String>, playlistId: String) {
        val now = nowSec()
        MuloDb.write(context, MuloDb.PLAYLIST_TRACKS) { d ->
            for (id in trackIds) insertMember(d, playlistId, id, now)
        }
    }

    fun removeTrackFromPlaylist(trackId: String, playlistId: String) {
        MuloDb.write(context, MuloDb.PLAYLIST_TRACKS) { d ->
            d.delete("playlist_tracks", "track_id = ? AND playlist_id = ?", arrayOf(trackId, playlistId))
        }
    }

    private fun insertMember(d: SQLiteDatabase, playlistId: String, trackId: String, addedAtSec: Long) {
        d.insertWithOnConflict(
            "playlist_tracks", null,
            ContentValues().apply { put("playlist_id", playlistId); put("track_id", trackId); put("added_at", addedAtSec) },
            SQLiteDatabase.CONFLICT_IGNORE,
        )
    }

    /** 좋아요한 곡인지. */
    fun isFavorite(trackId: String): Boolean =
        db.rawQuery(
            "SELECT 1 FROM playlist_tracks WHERE playlist_id = ? AND track_id = ? LIMIT 1",
            arrayOf(FAVORITES_ID, trackId),
        ).use { it.moveToFirst() }

    /** 좋아요를 켜고 끈다. 바뀐 뒤의 상태를 돌려준다 (화면도 바뀜 알림으로 목록을 다시 읽는다). */
    fun toggleFavorite(trackId: String): Boolean {
        var now = false
        MuloDb.write(context, MuloDb.PLAYLIST_TRACKS) { d ->
            val has = d.rawQuery(
                "SELECT 1 FROM playlist_tracks WHERE playlist_id = ? AND track_id = ? LIMIT 1",
                arrayOf(FAVORITES_ID, trackId),
            ).use { it.moveToFirst() }
            if (has) {
                d.delete("playlist_tracks", "playlist_id = ? AND track_id = ?", arrayOf(FAVORITES_ID, trackId))
            } else {
                insertMember(d, FAVORITES_ID, trackId, nowSec())
            }
            now = !has
        }
        return now
    }

    // ---------------- 받은 곡 등록 ----------------

    /**
     * 네이티브가 받아서 저장한 곡을 보관함에 넣는다 (곡 · 재생목록 · 커버 · 색 · 가사를 한 번에).
     * 같은 곡을 두 번 넣어도 한 번만 들어간다. 불러오는 폴더에서 빼서 숨겨 둔 같은 곡이면 숨김만 푼다.
     */
    fun register(r: AppDb.Registration) {
        MuloDb.write(
            context, MuloDb.TRACKS, MuloDb.PLAYLIST_TRACKS, MuloDb.COVERS, MuloDb.COVER_COLORS, MuloDb.LYRICS_FILES,
        ) { d ->
            val track = mapOf(
                "id" to r.trackId, "title" to r.title, "artist" to r.artist, "album" to r.album, "genre" to r.genre,
                "durationMs" to r.durationMs, "uri" to r.uri, "folder" to r.folder, "source" to "download",
                "addedAtSec" to r.addedAtSec, "mime" to r.mime,
            )
            d.insertWithOnConflict("tracks", null, trackValues(track), SQLiteDatabase.CONFLICT_IGNORE)
            d.execSQL("UPDATE tracks SET hidden = 0 WHERE uri = ? AND hidden = 1", arrayOf(r.uri))
            r.playlistIds.forEachIndexed { i, pid -> insertMember(d, pid, r.trackId, r.addedAtSec + i) }
            r.cover?.let { cover ->
                val v = ContentValues().apply {
                    put("key", "track:${r.trackId}")
                    put("path", cover.optString("path", ""))
                    if (cover.isNull("url") || !cover.has("url")) putNull("url") else put("url", cover.getString("url"))
                    put("scale", cover.optDouble("scale", 1.0))
                    put("dx", cover.optDouble("dx", 0.0))
                    put("dy", cover.optDouble("dy", 0.0))
                    put("rotation", cover.optDouble("rotation", 0.0))
                }
                d.insertWithOnConflict("covers", null, v, SQLiteDatabase.CONFLICT_REPLACE)
            }
            r.color?.let {
                d.insertWithOnConflict(
                    "cover_colors", null,
                    ContentValues().apply { put("key", "track:${r.trackId}"); put("color", it) },
                    SQLiteDatabase.CONFLICT_REPLACE,
                )
            }
            r.lyricsPath?.let {
                d.insertWithOnConflict(
                    "lyrics_files", null,
                    ContentValues().apply { put("track_id", r.trackId); put("path", it) },
                    SQLiteDatabase.CONFLICT_REPLACE,
                )
            }
        }
    }

    private fun deleteQuietly(path: String) {
        try {
            File(path).delete()
        } catch (_: Exception) {
            // 이미 없으면 그만.
        }
    }

    private fun Cursor.str(column: String): String = getString(getColumnIndexOrThrow(column)) ?: ""
    private fun Cursor.long(column: String): Long = getLong(getColumnIndexOrThrow(column))

    companion object {
        /** 즐겨찾기 재생목록 id (Dart `Playlist.favoritesId`와 같다). */
        const val FAVORITES_ID = "favorites"
    }
}
