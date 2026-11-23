package com.mulo.app

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * 받는 중 알림을 붙들어 앱 프로세스가 백그라운드에서 죽지 않게 하는 포그라운드 서비스(dataSync).
 * 받기 자체는 Dart가 같은 프로세스에서 한다. 서비스가 하는 일은 프로세스를 살려 두는 것뿐이다.
 */
class DownloadForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val content = DownloadNotifications.lastProgress
        // 프로세스가 죽었다 되살아난 경우 등: 보여 줄 내용이 없으면 바로 끝낸다.
        if (content == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        val notification = DownloadNotifications.buildProgress(this, content)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                DownloadNotifications.PROGRESS_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(DownloadNotifications.PROGRESS_ID, notification)
        }
        return START_NOT_STICKY
    }

    /**
     * Android 15+: dataSync 포그라운드 서비스는 24시간에 합쳐 약 6시간까지만 돈다. 한도에 닿으면 시스템이 이 함수를 부르고,
     * 곧바로 멈추지 않으면 앱이 강제 종료된다. 알림은 일반 알림으로 남기고(떼어 내기) 서비스를 멈춘다.
     * 앱이 다시 앞에 오면 다음 진행 알림이 서비스를 새로 시작한다.
     */
    override fun onTimeout(startId: Int, fgsType: Int) {
        PlaybackStore.logStop(applicationContext, "download: dataSync timeout")
        wanted = false
        stopForeground(STOP_FOREGROUND_DETACH)
        stopSelf(startId)
    }

    override fun onDestroy() {
        wanted = false
        super.onDestroy()
    }

    companion object {
        /** 서비스로 붙들기로 한 상태. 이 동안은 화면이 없어도 Flutter 엔진(받기를 하는 Dart)을 살려 둔다. */
        @Volatile
        var wanted = false

        /** 앞에 붙든다. 앱이 백그라운드라 시작할 수 없으면 false (일반 알림으로 보여 준다). */
        fun start(context: Context): Boolean = try {
            wanted = true
            val intent = Intent(context, DownloadForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            true
        } catch (e: Exception) {
            wanted = false
            false
        }

        fun stop(context: Context) {
            wanted = false
            MuloEngine.releaseWhenIdle()
            context.stopService(Intent(context, DownloadForegroundService::class.java))
        }
    }
}
