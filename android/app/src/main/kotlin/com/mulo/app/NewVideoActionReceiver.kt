package com.mulo.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** 새 영상 알림의 "취소" 버튼: 그 알림을 걷는다. 앱 화면은 열지 않는다. */
class NewVideoActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != NewVideoNotifications.ACTION_DISMISS) return
        val id = intent.getIntExtra(NewVideoNotifications.EXTRA_NOTIFICATION_ID, 0)
        if (id != 0) NewVideoNotifications.cancel(context, id)
    }
}
