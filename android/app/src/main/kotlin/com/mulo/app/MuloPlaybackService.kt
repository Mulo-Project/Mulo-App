package com.mulo.app

import android.content.Intent
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

/**
 * 재생 알림 · 포그라운드 서비스. 소리와 세션은 [PlaybackHub]가 쥐고, 이 서비스는 알림을 띄우고
 * 재생 중에 프로세스가 죽지 않게 지킨다. 서비스와 세션 객체는 Kotlin이 쥐고 닫기(X) · 밀어서 지우기로 죽지 않는다.
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

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession = PlaybackHub.session

    fun showSession() {
        if (!sessions.contains(PlaybackHub.session)) addSession(PlaybackHub.session)
    }

    fun hideSession() {
        if (sessions.contains(PlaybackHub.session)) removeSession(PlaybackHub.session)
    }

    // 앱이 최근 작업에서 밀려 사라지면 대기열도 사라지므로 재생 · 알림을 비운다 (서비스 · 세션 객체는 남는다).
    override fun onTaskRemoved(rootIntent: Intent?) {
        PlaybackHub.reset()
    }

    override fun onDestroy() {
        PlaybackHub.service = null
        super.onDestroy()
    }
}
