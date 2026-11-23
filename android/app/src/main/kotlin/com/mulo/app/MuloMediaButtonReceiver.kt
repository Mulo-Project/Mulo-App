package com.mulo.app

import android.content.Context
import android.app.ForegroundServiceStartNotAllowedException
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.media3.session.MediaButtonReceiver

/**
 * 앱이 꺼져 있거나 프로세스가 죽은 뒤에도 블루투스 이어폰 · 차량의 미디어 버튼을 받아 재생 서비스를 깨운다.
 * 이어 재생해도 되는 상태(일시정지로 알림이 살아 있던 때)일 때만 포그라운드 서비스로 띄운다.
 * 알림을 지웠거나 재생을 끝낸 뒤라면 서비스는 버튼을 무시하고 바로 끝난다 ([MuloPlaybackService]).
 */
class MuloMediaButtonReceiver : MediaButtonReceiver() {
    private var appContext: Context? = null

    override fun shouldStartForegroundService(context: Context, intent: Intent): Boolean {
        appContext = context.applicationContext
        return PlaybackStore.isResumable(context.applicationContext)
    }

    // 백그라운드에서 포그라운드 서비스를 못 띄운 경우 (Android 12+). 조용히 실패해 원인을 알 수 없었으므로 기록을 남긴다.
    @RequiresApi(Build.VERSION_CODES.S)
    override fun onForegroundServiceStartNotAllowedException(
        intent: Intent,
        e: ForegroundServiceStartNotAllowedException,
    ) {
        super.onForegroundServiceStartNotAllowedException(intent, e)
        appContext?.let { PlaybackStore.logStop(it, "button: foreground start not allowed") }
    }
}
