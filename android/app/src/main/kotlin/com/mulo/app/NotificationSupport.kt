package com.mulo.app

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build

/** 받기 · 새 영상 알림이 함께 쓰는 알림 도우미 (동작은 각 알림 파일에 있던 것과 같다). */
internal object NotificationSupport {
    /** 알림 인텐트의 공통 플래그: 같은 요청 코드면 내용을 갱신하고, 바꿀 수 없게 만든다. */
    const val PENDING_FLAGS = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

    fun manager(context: Context): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Suppress("DEPRECATION")
    fun builder(context: Context, channel: String): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(context, channel)
        else Notification.Builder(context)

    fun smallIcon(context: Context): Int =
        context.resources.getIdentifier("ic_stat_mulo", "drawable", context.packageName)

    @Suppress("DEPRECATION")
    fun addAction(b: Notification.Builder, label: String, pi: PendingIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            b.addAction(Notification.Action.Builder(null as Icon?, label, pi).build())
        } else {
            b.addAction(0, label, pi)
        }
    }
}
