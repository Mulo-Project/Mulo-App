package com.mulo.app

import android.content.Intent
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

/**
 * 재생 알림 · 포그라운드 서비스. 소리와 세션은 [PlaybackHub]가 쥐고, 이 서비스는 알림을 띄우고
 * 재생 중에 프로세스가 죽지 않게 지킨다. 서비스와 세션 객체는 Kotlin이 쥐고 닫기(X) · 밀어서 지우기로 죽지 않는다.
 *
 * 앱이 꺼진 뒤 블루투스 버튼이 오면 [MuloMediaButtonReceiver]가 이 서비스를 깨우고,
 * [PlaybackHub.init]이 저장해 둔 대기열을 되살려 버튼을 처리한다.
 */
class MuloPlaybackService : MediaSessionService() {
    override fun onCreate() {
        super.onCreate()
        PlaybackHub.init(applicationContext)
        PlaybackHub.service = this
        val provider = DefaultMediaNotificationProvider.Builder(this)
            .setChannelId("com.mulo.app.playback")
            .setChannelName(R.string.notif_channel_playback)
            .build()
        provider.setSmallIcon(R.drawable.ic_stat_mulo)
        setMediaNotificationProvider(provider)
        if (PlaybackHub.isNotificationVisible) showSession()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 알림을 지웠거나 재생을 끝낸 뒤에 온 미디어 버튼: 곡이 저절로 켜지지 않게 무시하고 서비스를 끝낸다.
        if (intent?.action == Intent.ACTION_MEDIA_BUTTON && PlaybackHub.isGated) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        // 알림을 지운 뒤에도 버튼으로 재생하는 설정이면 정리된 세션을 되살린다.
        if (intent?.action == Intent.ACTION_MEDIA_BUTTON) PlaybackHub.reviveForButton()
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = PlaybackHub.session

    fun showSession() {
        val session = PlaybackHub.session ?: return
        if (!sessions.contains(session)) addSession(session)
    }

    fun hideSession() {
        val session = PlaybackHub.session ?: return
        if (sessions.contains(session)) removeSession(session)
    }

    // 최근 작업에서 앱을 밀었을 때: 재생 중이면 계속하고, 멈춰 있으면 알림이 사라지므로 세션도 정리한다.
    override fun onTaskRemoved(rootIntent: Intent?) {
        if (!PlaybackHub.exo.playWhenReady) PlaybackHub.endSession()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        PlaybackHub.service = null
        super.onDestroy()
    }
}
