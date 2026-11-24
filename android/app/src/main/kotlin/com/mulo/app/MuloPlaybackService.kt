package com.mulo.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
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
            endWithoutPlaying(startId)
            return START_NOT_STICKY
        }
        // 버튼이 깨운 서비스는 세션 · 알림을 갖춰 재생할 수 있게 한다 (알림을 지운 뒤 이어 재생하는 설정 · 앱이 알림을 꺼 둔 경우 포함).
        if (intent?.action == Intent.ACTION_MEDIA_BUTTON && !PlaybackHub.prepareForButton()) {
            PlaybackStore.logStop(applicationContext, "button: ignored (no queue)")
            endWithoutPlaying(startId)
            return START_NOT_STICKY
        }
        return super.onStartCommand(intent, flags, startId)
    }

    /**
     * 버튼 인텐트를 받고도 재생하지 않고 끝낼 때. 알림 · 이어폰 버튼은 포그라운드 서비스로 시작되므로(`getForegroundService` · `startForegroundService`)
     * 기한 안에 `startForeground`를 부르지 않고 끝내면 시스템이 앱을 강제 종료한다 (ForegroundServiceDidNotStartInTimeException).
     * 잠깐 알림을 올려 약속을 지킨 뒤 바로 치우고 끝낸다.
     */
    private fun endWithoutPlaying(startId: Int) {
        runCatching {
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                manager.createNotificationChannel(
                    NotificationChannel(CHANNEL_ID, getString(R.string.notif_channel_playback), NotificationManager.IMPORTANCE_LOW),
                )
            }
            val notification = NotificationSupport.builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_mulo)
                .setContentTitle(getString(R.string.notif_channel_playback))
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(PLACEHOLDER_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(PLACEHOLDER_ID, notification)
            }
            stopForeground(STOP_FOREGROUND_REMOVE)
        }.onFailure { PlaybackStore.logStop(applicationContext, "button: placeholder foreground failed: ${it.message}") }
        stopSelf(startId)
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
    // 미리 듣기는 메인 플레이어가 아니라 Dart의 플레이어가 내므로, 미리 듣기가 소리를 내는 동안은 그대로 둔다.
    override fun onTaskRemoved(rootIntent: Intent?) {
        MuloLog.d(
            MuloLog.PLAYBACK,
            "앱 밀기: 미리듣기소리=${PlaybackHub.isPreviewPlaying} 미리듣기알림=${PlaybackHub.isPreviewing} 메인재생=${PlaybackHub.exo.playWhenReady}",
        )
        if (PlaybackHub.isPreviewPlaying) {
            // 알림(포그라운드)을 유지한다.
        } else if (PlaybackHub.isPreviewing) {
            PlaybackHub.setSession(null)
        } else if (!PlaybackHub.exo.playWhenReady) {
            PlaybackHub.endSession()
        }
        super.onTaskRemoved(rootIntent)
    }

    /**
     * 세션은 서비스보다 오래 산다 ([PlaybackHub]가 쥔다). 그런데 Media3는 서비스가 세션을 올릴 때 알림용 컨트롤러를 만들어 세션에 붙이고,
     * 서비스가 죽어도 스스로 떼지 않는다. 일시정지로 앱이 백그라운드에 오래 있으면 시스템이 서비스를 멈추는데, 그때 떼지 않으면
     * 죽은 서비스의 컨트롤러가 세션에 남아 알림 재생 버튼이 그 컨트롤러로 가고 (새 서비스가 아닌 죽은 서비스를 앞으로 올리려 해서)
     * 버튼이 먹지 않거나 포그라운드 시작 기한을 넘겨 앱이 강제 종료된다. 서비스가 죽을 때 세션을 떼어 컨트롤러를 정리한다.
     */
    override fun onDestroy() {
        hideSession()
        if (PlaybackHub.service === this) PlaybackHub.service = null
        super.onDestroy()
    }

    private companion object {
        const val CHANNEL_ID = "com.mulo.app.playback"

        /** Media3 기본 알림 번호와 같게 둔다 (잠깐 올린 알림이 곧 같은 자리에서 치워진다). */
        const val PLACEHOLDER_ID = 1001
    }
}
