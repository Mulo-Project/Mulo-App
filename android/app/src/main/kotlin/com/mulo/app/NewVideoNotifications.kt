package com.mulo.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

/**
 * 구독 채널 새 영상 알림. 영상마다 알림 하나를 띄우고 "바로 받기" · "취소" 버튼을 단다.
 * 여러 개면 묶음 알림으로 묶는다. 글 · 색은 Dart가 넘긴 값을 쓴다.
 * 알림 본문을 누르면 앱이 열려 새 영상 목록이 뜨고, "바로 받기"는 앱을 열어 받기를 시작한다.
 */
object NewVideoNotifications {
    const val ACTION_OPEN = "com.mulo.app.subscriptions.OPEN_NEW_VIDEOS"
    const val ACTION_DOWNLOAD = "com.mulo.app.subscriptions.DOWNLOAD_NEW_VIDEO"
    const val ACTION_DISMISS = "com.mulo.app.subscriptions.DISMISS_NEW_VIDEO"
    const val EXTRA_NOTIFICATION_ID = "notificationId"

    private const val CHANNEL = "com.mulo.app.new_videos"
    private const val GROUP = "com.mulo.app.new_videos.group"
    private const val SUMMARY_ID = 4001
    private const val VIDEO_ID_BASE = 4100

    /** 한 번에 띄울 영상 알림 수 (그 밖의 영상은 묶음 알림의 개수에만 센다). */
    private const val MAX_VIDEO_NOTIFICATIONS = 8

    private fun manager(context: Context) = NotificationSupport.manager(context)

    private fun canNotify(context: Context): Boolean =
        (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) &&
            manager(context).areNotificationsEnabled()

    /** 알림이 막혀 있는지: 권한 · 앱 알림 설정이 꺼졌거나, 새 영상 알림 채널을 껐을 때. */
    fun isBlocked(context: Context): Boolean {
        if (!canNotify(context)) return true
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val ch = manager(context).getNotificationChannel(CHANNEL) ?: return false
        return ch.importance == NotificationManager.IMPORTANCE_NONE
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val name = SubscriptionStore.text(context, "channelName").ifEmpty { CHANNEL }
        manager(context).createNotificationChannel(
            NotificationChannel(CHANNEL, name, NotificationManager.IMPORTANCE_DEFAULT).apply { setShowBadge(true) },
        )
    }

    private fun builder(context: Context) = NotificationSupport.builder(context, CHANNEL)

    private fun notificationId(videoId: String) = VIDEO_ID_BASE + (videoId.hashCode() and 0xFFFFF)

    /**
     * 새 영상마다 알림을 띄운다 (많으면 최신 몇 개만). 둘 이상이면 묶음 알림도 띄운다.
     * 알림이 막혀 있어 띄우지 못했으면 false (영상이 없으면 true).
     */
    fun showVideos(context: Context, videos: List<NewVideo>): Boolean {
        if (videos.isEmpty()) return true
        ensureChannel(context)
        if (isBlocked(context)) return false
        val nm = manager(context)
        val newest = videos.sortedByDescending { it.publishedMs }.take(MAX_VIDEO_NOTIFICATIONS)
        for (v in newest) nm.notify(notificationId(v.id), buildVideo(context, v))
        if (videos.size > 1) nm.notify(SUMMARY_ID, buildSummary(context, videos))
        return true
    }

    private fun buildVideo(context: Context, v: NewVideo): Notification {
        val id = notificationId(v.id)
        val b = builder(context)
            .setSmallIcon(smallIcon(context))
            .setContentTitle(v.title)
            .setContentText(v.channelName)
            .setStyle(Notification.BigTextStyle().bigText(v.channelName))
            .setGroup(GROUP)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_RECOMMENDATION)
            .setWhen(v.publishedMs)
            .setShowWhen(true)
        SubscriptionStore.color(context).takeIf { it != 0 }?.let { b.setColor(it) }
        NotificationArt.loadBlocking(v.thumbnailUrl)?.let { b.setLargeIcon(it) }
        openIntent(context)?.let { b.setContentIntent(it) }
        downloadIntent(context, v, id)?.let { addAction(b, SubscriptionStore.text(context, "downloadLabel"), it) }
        addAction(b, SubscriptionStore.text(context, "cancelLabel"), dismissIntent(context, id))
        return b.build()
    }

    private fun buildSummary(context: Context, videos: List<NewVideo>): Notification {
        val names = videos.map { it.channelName }.distinct().joinToString(", ")
        val body = SubscriptionStore.text(context, "body")
            .replace("%CHANNELS%", names)
            .replace("%COUNT%", videos.size.toString())
        val b = builder(context)
            .setSmallIcon(smallIcon(context))
            .setContentTitle(SubscriptionStore.text(context, "title"))
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setGroup(GROUP)
            .setGroupSummary(true)
            .setAutoCancel(true)
        SubscriptionStore.color(context).takeIf { it != 0 }?.let { b.setColor(it) }
        openIntent(context)?.let { b.setContentIntent(it) }
        return b.build()
    }

    private fun addAction(b: Notification.Builder, label: String, pi: PendingIntent) =
        NotificationSupport.addAction(b, label, pi)

    private fun smallIcon(context: Context) = NotificationSupport.smallIcon(context)

    /** 알림 본문 누름: 앱을 열고 새 영상 목록으로 보낸다 (MainActivity가 [ACTION_OPEN]을 받는다). */
    private fun openIntent(context: Context): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        launch.action = ACTION_OPEN
        return PendingIntent.getActivity(
            context,
            SUMMARY_ID,
            launch,
            NotificationSupport.PENDING_FLAGS,
        )
    }

    /** "바로 받기": 앱을 열어 이 영상을 받기 대기열에 넣는다 (앱이 꺼져 있으면 시작 직후 다시 뒤로 보낸다). */
    private fun downloadIntent(context: Context, v: NewVideo, id: Int): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        launch.action = ACTION_DOWNLOAD
        launch.putExtra(EXTRA_NOTIFICATION_ID, id)
        launch.putExtra("videoId", v.id)
        launch.putExtra("title", v.title)
        launch.putExtra("channelId", v.channelId)
        launch.putExtra("channelName", v.channelName)
        launch.putExtra("thumbnail", v.thumbnailUrl)
        return PendingIntent.getActivity(
            context,
            id,
            launch,
            NotificationSupport.PENDING_FLAGS,
        )
    }

    /** "취소": 이 알림을 걷는다 (앱은 열지 않는다). */
    private fun dismissIntent(context: Context, id: Int): PendingIntent {
        val intent = Intent(ACTION_DISMISS)
            .setComponent(ComponentName(context, NewVideoActionReceiver::class.java))
            .putExtra(EXTRA_NOTIFICATION_ID, id)
        return PendingIntent.getBroadcast(
            context,
            id xor 0x40000000,
            intent,
            NotificationSupport.PENDING_FLAGS,
        )
    }

    fun cancel(context: Context, id: Int) = manager(context).cancel(id)

    /** 새 영상 알림을 모두 걷는다 (묶음 알림 포함). */
    fun clear(context: Context) {
        val nm = manager(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            nm.activeNotifications
                .filter { it.id == SUMMARY_ID || it.id >= VIDEO_ID_BASE && it.id < VIDEO_ID_BASE + 0x100000 }
                .forEach { nm.cancel(it.id) }
        } else {
            nm.cancel(SUMMARY_ID)
        }
    }
}
