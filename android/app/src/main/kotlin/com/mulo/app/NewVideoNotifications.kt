package com.mulo.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/** 구독 채널 새 영상 알림. 글 · 색은 Dart가 넘긴 값을 쓴다. 누르면 앱이 열려 새 영상 목록으로 간다. */
object NewVideoNotifications {
    const val ACTION_OPEN = "com.mulo.app.subscriptions.OPEN_NEW_VIDEOS"
    private const val CHANNEL = "com.mulo.app.new_videos"
    private const val ID = 4001

    private fun manager(context: Context) =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun show(context: Context, channelNames: List<String>, count: Int) {
        // 알림 권한이 없으면 조용히 건너뛴다 (설정에서 켜도록 안내하는 건 앱 쪽 일).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        val nm = manager(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = SubscriptionStore.text(context, "channelName").ifEmpty { CHANNEL }
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, name, NotificationManager.IMPORTANCE_DEFAULT).apply {
                    setShowBadge(true)
                },
            )
        }
        val body = SubscriptionStore.text(context, "body")
            .replace("%CHANNELS%", channelNames.joinToString(", "))
            .replace("%COUNT%", count.toString())
        @Suppress("DEPRECATION")
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(context, CHANNEL)
        else Notification.Builder(context)
        val icon = context.resources.getIdentifier("ic_stat_mulo", "drawable", context.packageName)
        b.setSmallIcon(icon)
            .setContentTitle(SubscriptionStore.text(context, "title"))
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_RECOMMENDATION)
        SubscriptionStore.color(context).takeIf { it != 0 }?.let { b.setColor(it) }
        launchIntent(context)?.let { b.setContentIntent(it) }
        nm.notify(ID, b.build())
    }

    fun clear(context: Context) = manager(context).cancel(ID)

    /** 알림을 누르면 앱을 열고 새 영상 목록으로 보낸다 (MainActivity가 [ACTION_OPEN]을 받는다). */
    private fun launchIntent(context: Context): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        launch.action = ACTION_OPEN
        return PendingIntent.getActivity(
            context,
            ID,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
