package com.mulo.app

import android.content.Context
import android.content.Intent
import androidx.media3.session.MediaButtonReceiver

/**
 * 앱이 꺼져 있거나 프로세스가 죽은 뒤에도 블루투스 이어폰 · 차량의 미디어 버튼을 받아 재생 서비스를 깨운다.
 * 이어 재생해도 되는 상태(일시정지로 알림이 살아 있던 때)일 때만 포그라운드 서비스로 띄운다.
 * 알림을 지웠거나 재생을 끝낸 뒤라면 서비스는 버튼을 무시하고 바로 끝난다 ([MuloPlaybackService]).
 */
class MuloMediaButtonReceiver : MediaButtonReceiver() {
    override fun shouldStartForegroundService(context: Context, intent: Intent): Boolean =
        PlaybackStore.isResumable(context.applicationContext)
}
