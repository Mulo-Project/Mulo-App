package com.mulo.app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.CommandButton
import androidx.media3.session.MediaSession
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 재생의 주인: 소리를 내는 ExoPlayer, 미디어 세션, 알림 서비스 연결을 프로세스에 하나씩 쥔다.
 * 대기열(순서가 정해진 목록 · 현재 위치 · 반복)도 ExoPlayer가 쥐고 곡 넘김을 스스로 한다:
 * Flutter 화면(MainActivity)이 사라져도 서비스가 살아 있는 한 다음 곡으로 이어지고, 앱이 다시 켜지면 [getState]로 돌려받는다.
 * 대기열의 규칙(셔플 · 다음에 재생 · 이동 · 삭제)은 앱(Dart)이 정해 스냅샷으로 보낸다 ([setQueue]).
 * 앱(Dart)에는 [PlaybackChannel]로 명령을 받고 이벤트를 돌려준다. 모든 호출은 메인 스레드.
 */
object PlaybackHub {
    private const val ACTION_FAVORITE = "com.mulo.app.FAVORITE"
    private const val ACTION_CLOSE = "com.mulo.app.CLOSE"
    const val ACTION_OPEN_PLAYER = "com.mulo.app.OPEN_PLAYER"
    private val favoriteCommand = SessionCommand(ACTION_FAVORITE, Bundle.EMPTY)
    private val closeCommand = SessionCommand(ACTION_CLOSE, Bundle.EMPTY)

    private lateinit var context: Context
    private val main = Handler(Looper.getMainLooper())

    lateinit var exo: ExoPlayer
        private set
    lateinit var sessionPlayer: SessionPlayer
        private set
    lateinit var session: MediaSession
        private set

    /** 알림 서비스 (떠 있을 때만). */
    var service: MuloPlaybackService? = null

    /** 알림을 보여 줄지 (Dart가 알림을 끄면 false). */
    var isNotificationVisible = false
        private set

    /** 닫기(X)로 알림을 치운 상태: 다시 재생하기 전까지 알림을 띄우지 않는다. */
    private var dismissed = false

    private var sink: EventChannel.EventSink? = null
    private var pendingLoad: MethodChannel.Result? = null
    private var initialized = false

    /** 앱(Dart)만 해석하는 문자열 (셔플 여부 · 섞기 전 순서). 그대로 보관했다가 돌려준다. */
    private var extras = ""

    /** 대기열 곡별 커버 주소 (곡 id → 주소). 앱이 꺼진 사이 곡이 넘어가도 알림에 커버가 나오게 한다. */
    private var artById = mapOf<String, String>()

    /** 알림을 눌러 앱이 새로 켜졌는데 Dart가 아직 받아 가지 않은 요청. */
    private var openPlayerRequested = false

    fun init(appContext: Context) {
        if (initialized) return
        initialized = true
        context = appContext.applicationContext

        exo = ExoPlayer.Builder(context)
            // 다른 앱이 소리를 가져가면(영상, 통화) 멈추고, 이어폰이 빠지면 멈춘다.
            .setAudioAttributes(
                AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),
                true,
            )
            .setHandleAudioBecomingNoisy(true)
            .setWakeMode(C.WAKE_MODE_LOCAL)
            .build()
        exo.addListener(playerListener)
        EqualizerEngine.attach(exo.audioSessionId)

        sessionPlayer = SessionPlayer(exo) { name, positionMs -> emitCommand(name, positionMs) }
        val builder = MediaSession.Builder(context, sessionPlayer)
            .setId("mulo")
            .setCallback(sessionCallback)
        // 알림을 누르면 앱을 열고 현재 곡의 플레이어 화면으로 간다.
        val open = Intent(context, MainActivity::class.java)
            .setAction(ACTION_OPEN_PLAYER)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        builder.setSessionActivity(
            PendingIntent.getActivity(context, 0, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT),
        )
        session = builder.build()
    }

    // ── Dart → 네이티브 ──

    private fun repeatModeOf(name: String?) = when (name) {
        "all" -> Player.REPEAT_MODE_ALL
        "one" -> Player.REPEAT_MODE_ONE
        else -> Player.REPEAT_MODE_OFF
    }

    private fun repeatNameOf(mode: Int) = when (mode) {
        Player.REPEAT_MODE_ALL -> "all"
        Player.REPEAT_MODE_ONE -> "one"
        else -> "off"
    }

    private fun mediaItemOf(map: Map<*, *>): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(map["title"] as? String)
            .setArtist((map["artist"] as? String)?.ifEmpty { null })
            .setAlbumTitle((map["album"] as? String)?.ifEmpty { null })
            .setDurationMs((map["durationMs"] as? Number)?.toLong()?.takeIf { it > 0 })
            .setArtworkUri((map["id"] as? String)?.let { artById[it] }?.let { Uri.parse(it) })
            .build()
        return MediaItem.Builder()
            .setMediaId(map["id"] as? String ?: "")
            .setUri(map["uri"] as? String ?: "")
            .setMediaMetadata(metadata)
            .build()
    }

    /**
     * 대기열 스냅샷을 통째로 바꾼다. 현재 곡이 같으면 재생을 끊지 않고 앞뒤 목록만 맞춘다.
     * 다른 곡이면 새로 불러오고, 재생할 준비가 되면 [result]를 성공으로 끝낸다.
     */
    fun setQueue(map: Map<*, *>, result: MethodChannel.Result) {
        val items = (map["items"] as? List<*>)?.mapNotNull { it as? Map<*, *> } ?: emptyList()
        val playing = map["playing"] as? Boolean ?: false
        val positionMs = (map["positionMs"] as? Number)?.toLong()
        extras = map["extras"] as? String ?: ""
        exo.repeatMode = repeatModeOf(map["repeat"] as? String)
        pendingLoad?.error("interrupted", "다른 대기열을 불러와 중단됨", null)
        pendingLoad = null

        if (items.isEmpty()) {
            exo.stop()
            exo.clearMediaItems()
            result.success(null)
            return
        }
        dismissed = false
        val index = ((map["index"] as? Number)?.toInt() ?: 0).coerceIn(0, items.size - 1)
        val mediaItems = items.map { mediaItemOf(it) }
        val keepCurrent = exo.mediaItemCount > 0 &&
            exo.playbackState != Player.STATE_ENDED &&
            exo.currentMediaItem?.mediaId == mediaItems[index].mediaId

        if (keepCurrent) {
            // 듣던 곡은 그대로 두고 앞뒤만 바꾼다 (다음에 재생 · 순서 이동 · 삭제 · 반복 변경).
            val current = exo.currentMediaItemIndex
            if (current < exo.mediaItemCount - 1) exo.removeMediaItems(current + 1, exo.mediaItemCount)
            if (current > 0) exo.removeMediaItems(0, current)
            if (index > 0) exo.addMediaItems(0, mediaItems.subList(0, index))
            if (index < mediaItems.size - 1) exo.addMediaItems(mediaItems.subList(index + 1, mediaItems.size))
            if (positionMs != null) exo.seekTo(positionMs)
            exo.playWhenReady = playing
            sessionPlayer.refresh()
            result.success(null)
        } else {
            pendingLoad = result
            exo.setMediaItems(mediaItems, index, positionMs ?: 0L)
            exo.playWhenReady = playing
            exo.prepare()
            sessionPlayer.refresh()
        }
    }

    /** 대기열은 그대로 두고 [index]번 곡으로 처음부터 옮긴다. */
    fun skipTo(index: Int) {
        if (index < 0 || index >= exo.mediaItemCount) return
        dismissed = false
        exo.seekTo(index, 0L)
        if (exo.playbackState == Player.STATE_IDLE) exo.prepare()
    }

    fun play() {
        if (exo.mediaItemCount == 0) return
        dismissed = false
        // 끝까지 들은 곡은 처음부터 다시.
        if (exo.playbackState == Player.STATE_ENDED) exo.seekTo(0)
        exo.playWhenReady = true
    }

    fun pause() {
        exo.playWhenReady = false
    }

    fun seek(ms: Long) {
        if (exo.mediaItemCount > 0) exo.seekTo(ms)
    }

    fun artFor(id: String): Uri? = artById[id]?.let { Uri.parse(it) }

    /** true면 오디오 포커스를 따로 다루지 않아 다른 앱 소리와 겹쳐 재생한다. false면 뺏기면 멈춘다. */
    fun setMixWithOthers(mix: Boolean) {
        exo.setAudioAttributes(
            AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),
            !mix,
        )
    }

    /** 대기열 곡별 커버 주소를 받는다. 지금 곡은 앱이 [setSession]으로 보내므로 건드리지 않는다. */
    fun setQueueArt(map: Map<*, *>) {
        artById = map.entries.mapNotNull { (k, v) -> if (k is String && v is String) k to v else null }.toMap()
        for (i in 0 until exo.mediaItemCount) {
            if (i == exo.currentMediaItemIndex) continue
            val item = exo.getMediaItemAt(i)
            val art = artById[item.mediaId]?.let { Uri.parse(it) }
            if (item.mediaMetadata.artworkUri == art) continue
            val metadata = item.mediaMetadata.buildUpon().setArtworkUri(art).build()
            exo.replaceMediaItem(i, item.buildUpon().setMediaMetadata(metadata).build())
        }
    }

    /** 지금 쥐고 있는 대기열 스냅샷 (앱을 다시 켰을 때 복원용). 곡이 없으면 null. */
    fun getState(): Map<String, Any?>? {
        if (!initialized || exo.mediaItemCount == 0) return null
        val items = (0 until exo.mediaItemCount).map { i ->
            val item = exo.getMediaItemAt(i)
            mapOf(
                "id" to item.mediaId,
                "uri" to item.localConfiguration?.uri?.toString(),
                "title" to (item.mediaMetadata.title?.toString() ?: ""),
                "artist" to (item.mediaMetadata.artist?.toString() ?: ""),
                "album" to (item.mediaMetadata.albumTitle?.toString() ?: ""),
                "durationMs" to (item.mediaMetadata.durationMs ?: 0L),
            )
        }
        return mapOf(
            "items" to items,
            "index" to exo.currentMediaItemIndex,
            "playing" to (exo.playWhenReady && exo.playbackState != Player.STATE_ENDED),
            "repeat" to repeatNameOf(exo.repeatMode),
            "positionMs" to exo.currentPosition,
            "extras" to extras,
        )
    }

    /** 알림을 눌러 앱이 새로 켜졌는지 한 번 알려 주고 비운다. */
    fun takeOpenPlayerRequest(): Boolean {
        val requested = openPlayerRequested
        openPlayerRequested = false
        return requested
    }

    /** 알림을 눌렀다: 화면이 떠 있으면 바로 알리고, 아직 없으면 Dart가 시작할 때 가져가게 남긴다. */
    fun onOpenPlayerRequested() {
        val current = sink
        if (current != null) {
            current.success(mapOf("type" to "openPlayer"))
        } else {
            openPlayerRequested = true
        }
    }

    /** [map]이 null이면 알림을 치운다 (재생은 그대로). */
    fun setSession(map: Map<*, *>?) {
        if (map == null) {
            isNotificationVisible = false
            sessionPlayer.info = null
            service?.hideSession()
            return
        }
        val info = SessionInfo(map)
        sessionPlayer.info = info
        refreshLayout()
        if (dismissed) return
        isNotificationVisible = true
        ensureService()
        service?.showSession()
    }

    /** 알림 버튼 모양을 다시 맞춘다 (좋아요 모양은 Dart가 아는 현재 곡일 때만 보인다). */
    private fun refreshLayout() {
        val info = sessionPlayer.info ?: return
        session.setCustomLayout(customLayout(info, sessionPlayer.infoMatchesCurrent()))
    }

    /** 닫기(X): 재생을 멈추고 알림(포그라운드 서비스)을 치운다. 세션 · 프로세스는 남고, 다시 재생하면 알림이 돌아온다. */
    private fun dismissNotification() {
        dismissed = true
        isNotificationVisible = false
        service?.hideSession()
    }

    private fun ensureService() {
        if (service != null) return
        try {
            context.startService(Intent(context, MuloPlaybackService::class.java))
        } catch (_: Exception) {
            // 백그라운드에서는 서비스를 새로 못 띄울 수 있다: 알림만 못 보일 뿐 재생은 그대로.
        }
    }

    private fun customLayout(info: SessionInfo, current: Boolean): ImmutableList<CommandButton> {
        val close = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(R.drawable.ic_notif_close)
            .setDisplayName(info.closeLabel)
            .setSessionCommand(closeCommand)
            .build()
        if (info.preview || !current) return ImmutableList.of(close)
        val favorite = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(if (info.favorite) R.drawable.ic_notif_favorite else R.drawable.ic_notif_favorite_outline)
            .setDisplayName(if (info.favorite) info.unfavoriteLabel else info.favoriteLabel)
            .setSessionCommand(favoriteCommand)
            .build()
        return ImmutableList.of(favorite, close)
    }

    // ── 네이티브 → Dart ──

    fun setSink(newSink: EventChannel.EventSink?) {
        sink = newSink
    }

    private fun emit(map: Map<String, Any?>) {
        sink?.success(map)
    }

    private fun emitCommand(name: String, positionMs: Long?) {
        emit(mapOf("type" to "command", "name" to name, "positionMs" to positionMs))
    }

    private val ticker = object : Runnable {
        override fun run() {
            if (!exo.isPlaying) return
            emit(mapOf("type" to "position", "ms" to exo.currentPosition))
            main.postDelayed(this, 250)
        }
    }

    private val playerListener = object : Player.Listener {
        override fun onAudioSessionIdChanged(audioSessionId: Int) {
            EqualizerEngine.attach(audioSessionId)
        }

        override fun onEvents(player: Player, events: Player.Events) {
            sessionPlayer.refresh()
        }

        override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
            // 현재 곡이 바뀌었으니 좋아요 버튼 모양을 다시 맞춘다 (앱이 모르는 곡이면 숨긴다).
            refreshLayout()
            // 목록을 바꾸느라 생긴 전환은 앱이 시킨 것이라 알리지 않는다.
            if (mediaItem == null || reason == Player.MEDIA_ITEM_TRANSITION_REASON_PLAYLIST_CHANGED) return
            emit(mapOf("type" to "track", "index" to exo.currentMediaItemIndex, "id" to mediaItem.mediaId))
        }

        override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
            if (reason == Player.PLAY_WHEN_READY_CHANGE_REASON_END_OF_MEDIA_ITEM) return
            if (playWhenReady && dismissed) {
                // 이어폰 · 다른 경로로 다시 재생이 시작됐다: 알림도 다시 띄운다.
                dismissed = false
                isNotificationVisible = true
                ensureService()
                service?.showSession()
            }
            emit(mapOf("type" to "playing", "value" to playWhenReady))
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            main.removeCallbacks(ticker)
            if (isPlaying) main.post(ticker)
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_READY) {
                pendingLoad?.success(null)
                pendingLoad = null
            }
            // 반복 없이 대기열 끝까지 들었다.
            if (playbackState == Player.STATE_ENDED) emit(mapOf("type" to "ended"))
        }

        override fun onPositionDiscontinuity(
            oldPosition: Player.PositionInfo,
            newPosition: Player.PositionInfo,
            reason: Int,
        ) {
            if (reason == Player.DISCONTINUITY_REASON_SEEK) {
                emit(mapOf("type" to "position", "ms" to newPosition.positionMs))
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            val load = pendingLoad
            if (load != null) {
                load.error("load_failed", error.message, null)
                pendingLoad = null
                return
            }
            // 듣다가 못 여는 곡을 만나면 건너뛰고, 더 없으면 멈춘다.
            if (exo.hasNextMediaItem()) {
                exo.seekToNextMediaItem()
                exo.prepare()
            } else {
                exo.pause()
                emit(mapOf("type" to "ended"))
            }
        }
    }

    private val sessionCallback = object : MediaSession.Callback {
        override fun onConnect(session: MediaSession, controller: MediaSession.ControllerInfo): MediaSession.ConnectionResult {
            val commands = MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon()
                .add(favoriteCommand)
                .add(closeCommand)
                .build()
            return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                .setAvailableSessionCommands(commands)
                .build()
        }

        override fun onCustomCommand(
            session: MediaSession,
            controller: MediaSession.ControllerInfo,
            customCommand: SessionCommand,
            args: Bundle,
        ): ListenableFuture<SessionResult> {
            when (customCommand.customAction) {
                ACTION_FAVORITE -> emitCommand("favorite", null)
                // 닫기(X): 재생을 멈추고 알림을 치운다 (미리 듣기면 Dart가 미리 듣기를 끝낸다).
                ACTION_CLOSE -> {
                    if (sessionPlayer.info?.preview != true) {
                        exo.pause()
                        dismissNotification()
                    }
                    emitCommand("stop", null)
                }
            }
            return Futures.immediateFuture(SessionResult(SessionResult.RESULT_SUCCESS))
        }
    }
}
