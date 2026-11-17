package com.mulo.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.Executors

/**
 * 앱 DB 채널 (`music_app/db`). DB는 네이티브([MuloDb] · [LibraryDb])가 쥐고 Dart는 값을 넘겨 부르기만 한다.
 * 호출은 한 스레드에서 차례로 처리하고 결과는 메인 스레드로 돌려준다.
 *
 * 네이티브 → Dart (EventChannel `music_app/db/changes`): 테이블이 바뀔 때마다 바뀐 테이블 이름 목록.
 * 화면의 목록은 이 알림을 받아 다시 읽는다 (앱 밖(알림의 좋아요 · 받기 끝)에서 바뀐 것도 같은 길로 온다).
 */
class DbChannel(
    context: Context,
    messenger: BinaryMessenger,
) : NativeChannel(messenger, NAME) {
    private val lib = LibraryDb(context)
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val changes = EventChannel(messenger, CHANGES)

    private val listener: (Set<String>) -> Unit = { tables ->
        main.post { sink?.success(tables.toList()) }
    }

    @Volatile
    private var sink: EventChannel.EventSink? = null

    init {
        MuloDb.addListener(listener)
        changes.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, s: EventChannel.EventSink) {
                sink = s
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
        channel.setMethodCallHandler { call, result ->
            fun str(k: String) = call.argument<String>(k) ?: ""
            fun dbl(k: String) = call.argument<Number>(k)?.toDouble() ?: 0.0
            fun lng(k: String) = call.argument<Number>(k)?.toLong() ?: 0L
            fun strs(k: String) = call.argument<List<String>>(k) ?: emptyList()
            runAsync(io, result, "db") {
                when (call.method) {
                    // 곡
                    "tracks" -> lib.tracks()
                    "addTracks" -> lib.addTracks(call.argument<List<Map<String, Any?>>>("tracks") ?: emptyList())
                    "updateInfo" -> lib.updateInfo(str("id"), str("title"), str("artist"), str("album"), str("genre"))
                    "hide" -> { lib.hide(str("id")); null }
                    "hideMany" -> { lib.hideMany(strs("ids")); null }
                    "hiddenCount" -> lib.hiddenCount()
                    "hiddenTracks" -> lib.hiddenTracks()
                    "purgeHidden" -> lib.purgeHidden(call.argument<List<String>>("ids"), call.argument<Boolean>("emptyOnly") ?: false)
                    "deleteTrack" -> { lib.deleteTrack(str("id")); null }
                    // 커버 · 색
                    "covers" -> lib.covers()
                    "saveCover" -> {
                        lib.saveCover(str("key"), str("path"), call.argument<String>("url"), dbl("scale"), dbl("dx"), dbl("dy"), dbl("rotation"))
                        null
                    }
                    "saveCoverTransform" -> { lib.saveCoverTransform(str("key"), dbl("scale"), dbl("dx"), dbl("dy"), dbl("rotation")); null }
                    "removeCover" -> { lib.removeCover(str("key")); null }
                    "coverColors" -> lib.coverColors()
                    "saveCoverColor" -> { lib.saveCoverColor(str("key"), lng("color")); null }
                    "removeCoverColor" -> { lib.removeCoverColor(str("key")); null }
                    // 가사
                    "lyricsPath" -> lib.lyricsPath(str("trackId"))
                    "saveLyricsPath" -> { lib.saveLyricsPath(str("trackId"), str("path")); null }
                    "removeLyrics" -> { lib.removeLyrics(str("trackId")); null }
                    // 재생 기록
                    "recordPlay" -> lib.recordPlay(str("trackId"), lng("playedAtSec"), lng("listenedMs"))
                    "updateListened" -> { lib.updateListened(lng("id"), lng("listenedMs")); null }
                    "plays" -> lib.plays()
                    // 재생목록
                    "playlists" -> lib.playlists()
                    "playlistTracks" -> lib.playlistTracks(str("playlistId"))
                    "createPlaylist" -> lib.createPlaylist(str("name"))
                    "reorderPlaylists" -> { lib.reorderPlaylists(strs("ids")); null }
                    "renamePlaylist" -> { lib.renamePlaylist(str("id"), str("name")); null }
                    "deletePlaylist" -> { lib.deletePlaylist(str("id")); null }
                    "addTrackToPlaylists" -> { lib.addTrackToPlaylists(str("trackId"), strs("playlistIds")); null }
                    "addTracksToPlaylist" -> { lib.addTracksToPlaylist(strs("trackIds"), str("playlistId")); null }
                    "removeTrackFromPlaylist" -> { lib.removeTrackFromPlaylist(str("trackId"), str("playlistId")); null }
                    else -> throw UnsupportedOperationException(call.method)
                }
            }
        }
    }

    override fun dispose() {
        MuloDb.removeListener(listener)
        changes.setStreamHandler(null)
        sink = null
        io.shutdown()
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/db"
        const val CHANGES = "music_app/db/changes"
    }
}
