package com.mulo.app

import android.content.ContentUris
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * 기기 음악 불러오기 (상세 기능 #11): MediaStore에서 음악 파일 목록을 읽어 Flutter로 보낸다.
 * 권한 요청은 Flutter(permission_handler)가 먼저 한다.
 */
class MediaStoreChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "queryAudio" -> io.execute {
                    try {
                        val rows = queryAudio()
                        main.post { result.success(rows) }
                    } catch (e: SecurityException) {
                        main.post { result.error("permission", e.message, null) }
                    } catch (e: Exception) {
                        main.post { result.error("query_failed", e.message, null) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun queryAudio(): List<Map<String, Any?>> {
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
        )
        val rows = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
            collection,
            projection,
            "${MediaStore.Audio.Media.IS_MUSIC} != 0",
            null,
            "${MediaStore.Audio.Media.TITLE} ASC",
        )?.use { c ->
            val id = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val title = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artist = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val album = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val duration = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            while (c.moveToNext()) {
                val mediaId = c.getLong(id)
                rows += mapOf(
                    "id" to mediaId,
                    "title" to c.getString(title),
                    "artist" to c.getString(artist),
                    "album" to c.getString(album),
                    "durationMs" to c.getLong(duration),
                    "uri" to ContentUris.withAppendedId(collection, mediaId).toString(),
                )
            }
        }
        return rows
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    companion object {
        const val NAME = "music_app/media_store"
    }
}
