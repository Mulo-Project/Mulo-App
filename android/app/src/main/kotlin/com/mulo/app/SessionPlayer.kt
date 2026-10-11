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
    /** 이 내용이 어느 곡의 것인지 (앱이 꺼진 사이 곡이 넘어가면 달라진다). */
    val trackId = map["trackId"] as? String ?: ""
    val title = map["title"] as? String ?: ""
    val artist = map["artist"] as? String ?: ""
    val album = map["album"] as? String ?: ""
    val artUri = map["artUri"] as? String
    val durationMs = (map["durationMs"] as? Number)?.toLong() ?: 0L
    val positionMs = (map["positionMs"] as? Number)?.toLong() ?: 0L
    val playing = map["playing"] as? Boolean ?: false
    val favorite = map["favorite"] as? Boolean ?: false
    val preview = map["preview"] as? Boolean ?: false
    val favoriteLabel = map["favoriteLabel"] as? String ?: ""
    val unfavoriteLabel = map["unfavoriteLabel"] as? String ?: ""
    val closeLabel = map["closeLabel"] as? String ?: ""

    /** 곡 정보 숨기기 설정: 앱이 꺼진 사이 넘어간 곡에도 지켜야 해서 글자까지 받아 둔다. */
    val hideSongInfo = map["hideSongInfo"] as? Boolean ?: false
    val hiddenTitle = map["hiddenTitle"] as? String ?: ""
    val hiddenNote = map["hiddenNote"] as? String ?: ""
    val unknownArtist = map["unknownArtist"] as? String ?: ""
}

/**
 * 미디어 세션이 보는 플레이어. 알림 · 잠금화면 · 이어폰 버튼은 모두 이 플레이어에 말을 건다.
 *
 * - 메인 재생: 실제 소리를 내는 [exo]의 상태를 그대로 비춘다. 재생 · 일시정지 · 이동 · 이전 · 다음은
 *   대기열을 쥔 [exo]가 직접 처리한다 (앱이 꺼져 있어도 된다).
 *   곡 정보는 앱이 보낸 [info]가 현재 곡의 것이면 그대로 쓰고, 곡이 넘어갔으면 대기열에 실린 정보를 쓴다.
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

    /** 앱이 보낸 내용이 지금 재생 중인 곡의 것인지. */
    fun infoMatchesCurrent(): Boolean {
        val info = info ?: return false
        if (info.preview) return true
        return info.trackId.isNotEmpty() && info.trackId == exo.currentMediaItem?.mediaId
    }

    private fun metadataOf(info: SessionInfo): MediaMetadata {
        val item = exo.currentMediaItem
        if (info.preview || infoMatchesCurrent() || item == null) {
            return MediaMetadata.Builder()
                .setTitle(info.title)
                .setArtist(info.artist.ifEmpty { null })
                .setAlbumTitle(info.album.ifEmpty { null })
                .setArtworkUri(info.artUri?.let { Uri.parse(it) })
                .build()
        }
        // 앱이 모르는 새 곡 (앱이 꺼진 사이 넘어갔다): 대기열에 실린 정보로 보여 준다.
        if (info.hideSongInfo) {
            return MediaMetadata.Builder().setTitle(info.hiddenTitle).setArtist(info.hiddenNote.ifEmpty { null }).build()
        }
        val meta = item.mediaMetadata
        return MediaMetadata.Builder()
            .setTitle(meta.title ?: "")
            .setArtist((meta.artist?.toString() ?: info.unknownArtist).ifEmpty { null })
            .setAlbumTitle(meta.albumTitle)
            .setArtworkUri(meta.artworkUri ?: PlaybackHub.artFor(item.mediaId))
            .build()
    }

    override fun getState(): State {
        val info = info ?: return State.Builder().build()
        val preview = info.preview
        if (!preview && exo.mediaItemCount == 0) return State.Builder().build()

        val playWhenReady = if (preview) info.playing else exo.playWhenReady
        val playbackState = if (preview) STATE_READY else mapState(exo.playbackState)
        val itemDuration = exo.currentMediaItem?.mediaMetadata?.durationMs ?: C.TIME_UNSET
        val durationMs = when {
            !preview && exo.duration != C.TIME_UNSET && exo.duration > 0 -> exo.duration
            !preview && infoMatchesCurrent() && info.durationMs > 0 -> info.durationMs
            !preview && itemDuration != C.TIME_UNSET && itemDuration > 0 -> itemDuration
            preview && info.durationMs > 0 -> info.durationMs
            else -> C.TIME_UNSET
        }
        val positionMs = (if (preview) info.positionMs else exo.currentPosition).coerceAtLeast(0)
        val running = playWhenReady && playbackState == STATE_READY

        val metadata = metadataOf(info)
        val current = MediaItemData.Builder("current")
            .setMediaItem(MediaItem.Builder().setMediaId(if (preview) "mulo.preview" else "mulo.now_playing").setMediaMetadata(metadata).build())
            .setMediaMetadata(metadata)
            .setDurationUs(if (durationMs == C.TIME_UNSET) C.TIME_UNSET else durationMs * 1000)
            .setIsSeekable(durationMs != C.TIME_UNSET)
            .build()
        val hasPrevious = !preview && (exo.mediaItemCount > 1 || positionMs > 0)
        val hasNext = !preview && exo.mediaItemCount > 1
        val playlist = buildList {
            if (hasPrevious) add(placeholder("previous"))
            add(current)
            if (hasNext) add(placeholder("next"))
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
        if (hasPrevious) commands.addAll(Player.COMMAND_SEEK_TO_PREVIOUS, Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)
        if (hasNext) commands.addAll(Player.COMMAND_SEEK_TO_NEXT, Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)

        return State.Builder()
            .setAvailableCommands(commands.build())
            .setPlayWhenReady(playWhenReady, Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST)
            .setPlaybackState(playbackState)
            .setPlaylist(playlist)
            .setCurrentMediaItemIndex(if (hasPrevious) 1 else 0)
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
            if (playWhenReady && exo.playbackState == Player.STATE_ENDED) exo.seekTo(0)
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
            Player.COMMAND_SEEK_TO_NEXT, Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM -> if (!previewing) skipNext()
            // 3초 넘게 들었으면 처음으로, 아니면 이전 곡 (첫 곡이면 마지막 곡).
            Player.COMMAND_SEEK_TO_PREVIOUS, Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM -> if (!previewing) skipPrevious()
            else -> if (previewing) {
                onCommand("seek", positionMs)
            } else if (exo.mediaItemCount > 0) {
                exo.seekTo(positionMs)
                onCommand("seek", positionMs)
            }
        }
        return Futures.immediateVoidFuture()
    }

    /** 다음 곡. 마지막 곡이면 전체 반복일 때만 처음으로 돌아간다. */
    private fun skipNext() {
        val count = exo.mediaItemCount
        if (count == 0) return
        val next = exo.currentMediaItemIndex + 1
        when {
            next < count -> exo.seekTo(next, 0L)
            exo.repeatMode == Player.REPEAT_MODE_ALL -> exo.seekTo(0, 0L)
        }
    }

    private fun skipPrevious() {
        val count = exo.mediaItemCount
        if (count == 0) return
        val index = exo.currentMediaItemIndex
        when {
            exo.currentPosition > 3000 || count < 2 -> exo.seekTo(index, 0L)
            index == 0 -> exo.seekTo(count - 1, 0L)
            else -> exo.seekTo(index - 1, 0L)
        }
    }
}
