package com.mulo.app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
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
 * Flutter 화면(MainActivity)이 사라져도 서비스가 살아 있는 한 재생 · 세션은 그대로 있다.
 * 앱(Dart)에는 [PlaybackChannel]로 명령을 받고 이벤트를 돌려준다. 모든 호출은 메인 스레드.
 */
object PlaybackHub {
    private const val ACTION_FAVORITE = "com.mulo.app.FAVORITE"
    private const val ACTION_CLOSE = "com.mulo.app.CLOSE"
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

        sessionPlayer = SessionPlayer(exo) { name, positionMs -> emitCommand(name, positionMs) }
        val builder = MediaSession.Builder(context, sessionPlayer)
            .setId("mulo")
            .setCallback(sessionCallback)
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
            builder.setSessionActivity(
                PendingIntent.getActivity(context, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT),
            )
        }
        session = builder.build()
    }

    // ── Dart → 네이티브 ──

    fun load(uri: String, result: MethodChannel.Result) {
        pendingLoad?.error("interrupted", "다른 곡을 불러와 중단됨", null)
        pendingLoad = result
        dismissed = false
        exo.playWhenReady = false
        exo.setMediaItem(MediaItem.fromUri(uri))
        exo.prepare()
        sessionPlayer.refresh()
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
        session.setCustomLayout(customLayout(info))
        if (dismissed) return
        isNotificationVisible = true
        ensureService()
        service?.showSession()
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

    /** 앱이 최근 작업에서 밀려 사라졌을 때: 재생만 멈추고 서비스 · 세션은 그대로 둔다. */
    fun onTaskRemoved() {
        exo.playWhenReady = false
        emitCommand("stop", null)
    }

    private fun customLayout(info: SessionInfo): ImmutableList<CommandButton> {
        val close = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(R.drawable.ic_notif_close)
            .setDisplayName(info.closeLabel)
            .setSessionCommand(closeCommand)
            .build()
        if (info.preview) return ImmutableList.of(close)
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
        override fun onEvents(player: Player, events: Player.Events) {
            sessionPlayer.refresh()
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
            if (playbackState == Player.STATE_ENDED) emit(mapOf("type" to "completed"))
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
            pendingLoad?.error("load_failed", error.message, null)
            pendingLoad = null
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
