package com.mulo.app

import android.net.Uri
import android.os.Looper
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.SimpleBasePlayer
import androidx.media3.exoplayer.ExoPlayer
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/** Dart가 보내 준, 알림 · 잠금화면에 보여 줄 내용. */
class SessionInfo(map: Map<*, *>) {
    val title = map["title"] as? String ?: ""
    val artist = map["artist"] as? String ?: ""
    val album = map["album"] as? String ?: ""
    val artUri = map["artUri"] as? String
    val durationMs = (map["durationMs"] as? Number)?.toLong() ?: 0L
    val positionMs = (map["positionMs"] as? Number)?.toLong() ?: 0L
    val playing = map["playing"] as? Boolean ?: false
    val hasPrevious = map["hasPrevious"] as? Boolean ?: false
    val hasNext = map["hasNext"] as? Boolean ?: false
    val favorite = map["favorite"] as? Boolean ?: false
    val preview = map["preview"] as? Boolean ?: false
    val favoriteLabel = map["favoriteLabel"] as? String ?: ""
    val unfavoriteLabel = map["unfavoriteLabel"] as? String ?: ""
    val closeLabel = map["closeLabel"] as? String ?: ""
}

/**
 * 미디어 세션이 보는 플레이어. 알림 · 잠금화면 · 이어폰 버튼은 모두 이 플레이어에 말을 건다.
 *
 * - 메인 재생: 실제 소리를 내는 [exo]의 상태를 그대로 비춘다. 재생 · 일시정지 · 이동은 [exo]가 직접 처리하고,
 *   이전 · 다음은 앱의 대기열이 정하므로 [onCommand]로 Dart에 넘긴다.
 * - 미리 듣기: 소리는 Dart 쪽 플레이어가 내므로, Dart가 보내 준 상태를 보여 주고 조작은 모두 Dart에 넘긴다.
 *
 * 이전 · 다음 버튼이 알림에 보이도록 현재 곡 앞뒤에 자리 표시 항목을 둔다.
 */
class SessionPlayer(
    private val exo: ExoPlayer,
    private val onCommand: (name: String, positionMs: Long?) -> Unit,
) : SimpleBasePlayer(Looper.getMainLooper()) {

    var info: SessionInfo? = null
        set(value) {
            field = value
            invalidateState()
        }

    /** 메인 플레이어(exo)의 상태가 바뀌었을 때. */
    fun refresh() = invalidateState()

    private val previewing get() = info?.preview == true

    override fun getState(): State {
        val info = info ?: return State.Builder().build()
        val preview = info.preview

        val playWhenReady = if (preview) info.playing else exo.playWhenReady
        val playbackState = if (preview) STATE_READY else mapState(exo.playbackState)
        val durationMs = when {
            !preview && exo.duration != C.TIME_UNSET && exo.duration > 0 -> exo.duration
            info.durationMs > 0 -> info.durationMs
            else -> C.TIME_UNSET
        }
        val positionMs = (if (preview) info.positionMs else exo.currentPosition).coerceAtLeast(0)
        val running = playWhenReady && playbackState == STATE_READY

        val metadata = MediaMetadata.Builder()
            .setTitle(info.title)
            .setArtist(info.artist.ifEmpty { null })
            .setAlbumTitle(info.album.ifEmpty { null })
            .setArtworkUri(info.artUri?.let { Uri.parse(it) })
            .build()
        val current = MediaItemData.Builder("current")
            .setMediaItem(MediaItem.Builder().setMediaId(if (preview) "mulo.preview" else "mulo.now_playing").setMediaMetadata(metadata).build())
            .setMediaMetadata(metadata)
            .setDurationUs(if (durationMs == C.TIME_UNSET) C.TIME_UNSET else durationMs * 1000)
            .setIsSeekable(durationMs != C.TIME_UNSET)
            .build()
        val playlist = buildList {
            if (info.hasPrevious) add(placeholder("previous"))
            add(current)
            if (info.hasNext) add(placeholder("next"))
        }

        val commands = Player.Commands.Builder()
            .addAll(
                Player.COMMAND_PLAY_PAUSE,
                Player.COMMAND_STOP,
                Player.COMMAND_GET_CURRENT_MEDIA_ITEM,
                Player.COMMAND_GET_TIMELINE,
                Player.COMMAND_GET_METADATA,
            )
        if (durationMs != C.TIME_UNSET) commands.add(Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM)
        if (info.hasPrevious) commands.addAll(Player.COMMAND_SEEK_TO_PREVIOUS, Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)
        if (info.hasNext) commands.addAll(Player.COMMAND_SEEK_TO_NEXT, Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)

        return State.Builder()
            .setAvailableCommands(commands.build())
            .setPlayWhenReady(playWhenReady, Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST)
            .setPlaybackState(playbackState)
            .setPlaylist(playlist)
            .setCurrentMediaItemIndex(if (info.hasPrevious) 1 else 0)
            .setContentPositionMs(
                if (running) PositionSupplier.getExtrapolating(positionMs, 1f) else PositionSupplier.getConstant(positionMs),
            )
            .build()
    }

    private fun placeholder(id: String) = MediaItemData.Builder(id).build()

    private fun mapState(s: Int) = when (s) {
        Player.STATE_BUFFERING -> STATE_BUFFERING
        Player.STATE_READY -> STATE_READY
        Player.STATE_ENDED -> STATE_ENDED
        else -> STATE_IDLE
    }

    override fun handleSetPlayWhenReady(playWhenReady: Boolean): ListenableFuture<*> {
        if (previewing) {
            onCommand(if (playWhenReady) "play" else "pause", null)
        } else if (exo.mediaItemCount > 0) {
            exo.playWhenReady = playWhenReady
        }
        return Futures.immediateVoidFuture()
    }

    override fun handleStop(): ListenableFuture<*> {
        if (!previewing) exo.pause()
        onCommand("stop", null)
        return Futures.immediateVoidFuture()
    }

    override fun handleSeek(mediaItemIndex: Int, positionMs: Long, seekCommand: Int): ListenableFuture<*> {
        when (seekCommand) {
            Player.COMMAND_SEEK_TO_NEXT, Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM -> onCommand("next", null)
            // 3초 넘게 들었으면 처음으로, 아니면 이전 곡: 앱이 정한다.
            Player.COMMAND_SEEK_TO_PREVIOUS, Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM -> onCommand("previous", null)
            else -> if (previewing) {
                onCommand("seek", positionMs)
            } else if (exo.mediaItemCount > 0) {
                exo.seekTo(positionMs)
                onCommand("seek", positionMs)
            }
        }
        return Futures.immediateVoidFuture()
    }
}
