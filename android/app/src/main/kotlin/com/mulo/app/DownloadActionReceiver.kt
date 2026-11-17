package com.mulo.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * 받기 알림의 버튼을 받는다. 받기는 네이티브([DownloadEngine])가 하므로 취소 · 일시정지/이어받기 · 다시 시도는 앱 화면이나 Dart 없이
 * 여기서 바로 처리한다 (앱이 꺼져 있으면 엔진을 먼저 켠다). 미리듣기 버튼만 Dart가 처리한다.
 */
class DownloadActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        MuloLog.init(context.applicationContext)
        MuloLog.d(MuloLog.NATIVE, "받기 알림 수신기 호출: ${intent.action}")
        val key = DownloadNotifications.ACTIONS.entries.firstOrNull { it.value == intent.action }?.key ?: return
        if (key == "retry") {
            val id = intent.getStringExtra(DownloadNotifications.EXTRA_RETRY_ID) ?: return
            MuloEngine.obtain(context)
            MuloLog.d(MuloLog.NATIVE, "받기 다시 시도 요청 $id (엔진=${MuloEngine.downloads != null})")
            MuloEngine.downloads?.retry(id)
            return
        }
        // 엔진이 정리됐어도(앱이 꺼진 채 일시정지해 두는 동안 등) 버튼이 먹도록 엔진을 먼저 켠다. 대기열은 파일에서 되살아난다.
        MuloEngine.obtain(context)
        val downloads = MuloEngine.downloads
        if (downloads == null) MuloLog.d(MuloLog.NATIVE, "받기 알림 버튼 $key: 받기 엔진이 없음")
        if (downloads != null && downloads.onAction(key)) return
        // 받아 줄 엔진이 없으면(프로세스가 죽었다 되살아난 경우 등) 버튼이 먹지 않는 낡은 알림이므로 치운다.
        DownloadNotifications.clearProgress(context)
    }
}
