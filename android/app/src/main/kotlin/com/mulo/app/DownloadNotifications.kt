package com.mulo.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build

/** 받기 알림(진행 · 결과)을 만든다. 글자 · 색은 Dart가 넘긴 값을 그대로 쓴다. */
object DownloadNotifications {
    const val PROGRESS_ID = 2001
    private const val PROGRESS_CHANNEL = "com.mulo.app.download_progress"
    private const val DONE_CHANNEL = "com.mulo.app.download_done"
    private const val FAILED_CHANNEL = "com.mulo.app.download_failed"
    private const val RESULT_ID_BASE = 3000

    /** 받기 알림 본문을 눌러 앱을 열 때 인텐트에 싣는 값 (Dart의 받기 항목 id). */
    const val ACTION_OPEN_DOWNLOAD = "com.mulo.app.download.OPEN"
    const val EXTRA_OPEN_ID = "openId"

    // 알림 버튼 → 수신기 → Dart. 키는 Dart와 맞춘 이름.
    val ACTIONS = linkedMapOf(
        "preview" to "com.mulo.app.download.PREVIEW",
        "pausePreview" to "com.mulo.app.download.PAUSE_PREVIEW",
        "stopPreview" to "com.mulo.app.download.STOP_PREVIEW",
        "toggleHold" to "com.mulo.app.download.TOGGLE_HOLD",
        "cancel" to "com.mulo.app.download.CANCEL",
    )

    /** 서비스가 알림을 다시 만들 때 쓰는, 마지막으로 받은 진행 알림 내용. */
    @Volatile
    var lastProgress: Map<String, Any?>? = null

    private val resultIds = mutableSetOf<Int>()

    private fun manager(context: Context) = NotificationSupport.manager(context)

    fun createChannels(context: Context, a: Map<String, Any?>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = manager(context)
        fun channel(id: String, name: String?, importance: Int, badge: Boolean) {
            val c = NotificationChannel(id, name ?: id, importance)
            if (importance <= NotificationManager.IMPORTANCE_LOW) {
                c.setSound(null, null)
                c.enableVibration(false)
            }
            c.setShowBadge(badge)
            nm.createNotificationChannel(c)
        }
        channel(PROGRESS_CHANNEL, a["progressChannel"] as? String, NotificationManager.IMPORTANCE_LOW, false)
        channel(DONE_CHANNEL, a["doneChannel"] as? String, NotificationManager.IMPORTANCE_LOW, true)
        channel(FAILED_CHANNEL, a["failedChannel"] as? String, NotificationManager.IMPORTANCE_DEFAULT, true)
    }

    private fun builder(context: Context, channel: String) = NotificationSupport.builder(context, channel)

    private fun smallIcon(context: Context) = NotificationSupport.smallIcon(context)

    /** 알림을 누르면 앱을 연다. [openId]가 있으면 그 받기 항목의 상세 화면으로 간다. */
    private fun launchIntent(context: Context, openId: String?): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        if (!openId.isNullOrEmpty()) {
            launch.action = ACTION_OPEN_DOWNLOAD
            launch.putExtra(EXTRA_OPEN_ID, openId)
        }
        // 항목마다 요청 코드를 달리해야 알림마다 자기 항목을 가리킨다.
        val code = if (openId.isNullOrEmpty()) 0 else 1 + (openId.hashCode() and 0xFFFFF)
        return PendingIntent.getActivity(context, code, launch, NotificationSupport.PENDING_FLAGS)
    }

    private fun actionIntent(context: Context, key: String): PendingIntent {
        val intent = Intent(ACTIONS.getValue(key))
            .setComponent(ComponentName(context, DownloadActionReceiver::class.java))
        return PendingIntent.getBroadcast(
            context,
            ACTIONS.keys.indexOf(key),
            intent,
            NotificationSupport.PENDING_FLAGS,
        )
    }

    private fun addAction(context: Context, b: Notification.Builder, key: String, label: String) =
        NotificationSupport.addAction(b, label, actionIntent(context, key))

    fun buildProgress(context: Context, a: Map<String, Any?>): Notification {
        val body = a["body"] as? String
        val b = builder(context, PROGRESS_CHANNEL)
            .setSmallIcon(smallIcon(context))
            .setContentTitle(a["title"] as? String)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
        (a["color"] as? Number)?.let { b.setColor(it.toInt()) }
        (a["subText"] as? String)?.let { b.setSubText(it) }
        // 곡 이미지: 아직 못 받았으면 받은 뒤 같은 내용으로 알림을 다시 그린다.
        val art = a["artUri"] as? String
        NotificationArt.get(art) {
            lastProgress?.takeIf { it["artUri"] == art }?.let { showProgress(context, it) }
        }?.let { b.setLargeIcon(it) }
        val percent = (a["percent"] as? Number)?.toInt()
        b.setProgress(100, percent ?: 0, percent == null)
        launchIntent(context, a["openId"] as? String)?.let { b.setContentIntent(it) }
        val pause = a["pauseLabel"] as? String
        val stop = a["stopLabel"] as? String
        val preview = a["previewLabel"] as? String
        val cancel = a["cancelLabel"] as? String
        val hold = a["holdLabel"] as? String
        if (pause != null) addAction(context, b, "pausePreview", pause)
        if (stop != null) addAction(context, b, "stopPreview", stop)
        if (preview != null && pause == null) addAction(context, b, "preview", preview)
        if (hold != null) addAction(context, b, "toggleHold", hold)
        if (cancel != null) addAction(context, b, "cancel", cancel)
        return b.build()
    }

    fun showProgress(context: Context, a: Map<String, Any?>) {
        manager(context).notify(PROGRESS_ID, buildProgress(context, a))
    }

    fun clearProgress(context: Context) {
        manager(context).cancel(PROGRESS_ID)
    }

    fun showResult(context: Context, a: Map<String, Any?>) {
        val failed = a["failed"] == true
        val body = a["body"] as? String
        val id = RESULT_ID_BASE + (((a["id"] as? String) ?: "").hashCode() and 0xFFFFF)
        val b = builder(context, if (failed) FAILED_CHANNEL else DONE_CHANNEL)
            .setSmallIcon(smallIcon(context))
            .setContentTitle(a["title"] as? String)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
        (a["color"] as? Number)?.let { b.setColor(it.toInt()) }
        NotificationArt.get(a["artUri"] as? String) { showResult(context, a) }?.let { b.setLargeIcon(it) }
        launchIntent(context, a["openId"] as? String)?.let { b.setContentIntent(it) }
        synchronized(resultIds) { resultIds.add(id) }
        manager(context).notify(id, b.build())
    }

    fun clearResults(context: Context) {
        val nm = manager(context)
        synchronized(resultIds) {
            resultIds.forEach { nm.cancel(it) }
            resultIds.clear()
        }
    }
}
