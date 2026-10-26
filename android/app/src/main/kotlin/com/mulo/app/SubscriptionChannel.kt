package com.mulo.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * 채널 구독 새 영상 확인(`music_app/subscriptions`). Dart가 구독 채널 · 설정을 넘기면 WorkManager가
 * 주기적으로 확인한다 ([NewVideoWorker]). 알림을 누르면 [requestOpen]으로 Dart에 알린다.
 */
class SubscriptionChannel(
    private val context: Context,
    messenger: BinaryMessenger,
    private val moveToBack: () -> Unit,
) {
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
                    "takeDownloads" -> {
                        val list = synchronized(pendingDownloads) {
                            pendingDownloads.toList().also { pendingDownloads.clear() }
                        }
                        result.success(list)
                    }
                    "moveToBack" -> {
                        moveToBack()
                        result.success(null)
                    }
                    "checkNow" -> {
                        checkNow(context)
                        result.success(null)
                    }
                    "status" -> io.execute {
                        val status = try {
                            status(context)
                        } catch (e: Exception) {
                            emptyMap()
                        }
                        main.post { result.success(status) }
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
        const val CHECK_NOW_NAME = "mulo_new_videos_now"
        private val main = Handler(Looper.getMainLooper())
        private val io = Executors.newSingleThreadExecutor()

        /** 주기를 기다리지 않고 지금 한 번 확인한다 (와이파이 전용 설정과 상관없이 연결만 있으면). */
        fun checkNow(context: Context) {
            val request = OneTimeWorkRequestBuilder<NewVideoWorker>()
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .build()
            WorkManager.getInstance(context)
                .enqueueUniqueWork(CHECK_NOW_NAME, androidx.work.ExistingWorkPolicy.REPLACE, request)
        }

        /** 진단용 상태: 예약 여부, 알림 막힘, 마지막 확인 결과. */
        fun status(context: Context): Map<String, Any?> {
            val infos = WorkManager.getInstance(context).getWorkInfosForUniqueWork(WORK_NAME).get()
            val scheduled = infos.any { it.state != WorkInfo.State.CANCELLED && it.state != WorkInfo.State.FAILED }
            val run = SubscriptionStore.lastRun(context)
            return mapOf(
                "scheduled" to scheduled,
                "notificationsBlocked" to NewVideoNotifications.isBlocked(context),
                "lastRunMs" to (run["atMs"] as? Number)?.toLong(),
                "channels" to (run["channels"] as? Number)?.toInt(),
                "failed" to (run["failed"] as? Number)?.toInt(),
                "notified" to (run["notified"] as? Number)?.toInt(),
                "blocked" to (run["blocked"] == true),
            )
        }

        @Volatile
        private var active: MethodChannel? = null

        /** 새 영상 알림을 눌러 열라고 한 요청. Dart가 `takeOpen`으로 가져가면 비운다. */
        @Volatile
        private var pendingOpen = false

        /** 알림의 "바로 받기"로 들어온, Dart가 아직 가져가지 않은 받기 요청. */
        private val pendingDownloads = mutableListOf<Map<String, Any?>>()

        /** "바로 받기" 누름: 요청을 맡겨 두고 Dart에 알린다 (엔진이 아직 없으면 Dart가 켜질 때 가져간다). */
        fun requestDownload(request: Map<String, Any?>) {
            synchronized(pendingDownloads) { pendingDownloads.add(request) }
            main.post { active?.invokeMethod("download", null) }
        }

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
