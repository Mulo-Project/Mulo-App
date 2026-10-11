package com.mulo.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

/**
 * 채널 구독 새 영상 확인(`music_app/subscriptions`). Dart가 구독 채널 · 설정을 넘기면 WorkManager가
 * 주기적으로 확인한다 ([NewVideoWorker]). 알림을 누르면 [requestOpen]으로 Dart에 알린다.
 */
class SubscriptionChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)

    init {
        active = channel
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "sync" -> {
                        @Suppress("UNCHECKED_CAST")
                        sync(context, call.arguments as? Map<String, Any?> ?: emptyMap())
                        result.success(null)
                    }
                    "takeOpen" -> {
                        val open = pendingOpen
                        pendingOpen = false
                        result.success(open)
                    }
                    "clearNotification" -> {
                        NewVideoNotifications.clear(context)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("failed", e.message, null)
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        if (active === channel) active = null
    }

    companion object {
        const val NAME = "music_app/subscriptions"
        const val WORK_NAME = "mulo_new_videos"
        private val main = Handler(Looper.getMainLooper())

        @Volatile
        private var active: MethodChannel? = null

        /** 새 영상 알림을 눌러 열라고 한 요청. Dart가 `takeOpen`으로 가져가면 비운다. */
        @Volatile
        private var pendingOpen = false

        /** 알림 누름: 요청을 맡겨 두고 Dart에 알린다 (엔진이 아직 없으면 Dart가 켜질 때 가져간다). */
        fun requestOpen() {
            pendingOpen = true
            main.post { active?.invokeMethod("open", null) }
        }

        /** Dart가 넘긴 설정을 저장하고 주기 확인을 예약하거나 취소한다. */
        fun sync(context: Context, args: Map<String, Any?>) {
            SubscriptionStore.save(context, args)
            val enabled = args["enabled"] == true
            val hasChannels = (args["channels"] as? List<*>)?.isNotEmpty() == true
            val work = WorkManager.getInstance(context)
            if (!enabled || !hasChannels) {
                work.cancelUniqueWork(WORK_NAME)
                return
            }
            val hours = ((args["intervalHours"] as? Number)?.toLong() ?: 3L).coerceIn(1L, 24L)
            val network = if (args["wifiOnly"] == true) NetworkType.UNMETERED else NetworkType.CONNECTED
            val request = PeriodicWorkRequestBuilder<NewVideoWorker>(hours, TimeUnit.HOURS)
                .setConstraints(Constraints.Builder().setRequiredNetworkType(network).build())
                .build()
            work.enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.UPDATE, request)
        }
    }
}
