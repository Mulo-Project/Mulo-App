package com.mulo.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** 받기 알림의 버튼(미리듣기 · 일시정지 · 중지 · 취소)을 받아 Dart로 넘긴다. 앱 화면은 열지 않는다. */
class DownloadActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val key = DownloadNotifications.ACTIONS.entries.firstOrNull { it.value == intent.action }?.key ?: return
        DownloadNotificationPlugin.dispatch(key)
    }
}
