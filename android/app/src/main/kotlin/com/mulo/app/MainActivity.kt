package com.mulo.app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// 생체 인증(local_auth)이 FragmentActivity를 요구한다. 재생 · 알림은 PlaybackHub(서비스)가 쥐고 PlaybackChannel로 이어진다.
class MainActivity : FlutterFragmentActivity() {
    /** 화면에 떠 있는지. 새 인텐트가 들어올 때 앱이 뒤에 있었는지 알려고 쓴다. */
    private var resumed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        MuloEngine.activity = this
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    // 재생 알림을 누르면 현재 곡의 플레이어 화면으로 간다 (앱이 이미 떠 있을 때).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == PlaybackHub.ACTION_OPEN_PLAYER) PlaybackHub.onOpenPlayerRequested()
        if (intent?.action == DownloadNotifications.ACTION_OPEN_DOWNLOAD) {
            intent.getStringExtra(DownloadNotifications.EXTRA_OPEN_ID)?.let { DownloadNotificationPlugin.requestOpen(it) }
        }
        if (intent?.action == NewVideoNotifications.ACTION_OPEN) SubscriptionChannel.requestOpen()
        if (intent?.action == NewVideoNotifications.ACTION_DOWNLOAD) {
            intent.getStringExtra("videoId")?.let { videoId ->
                NewVideoNotifications.cancel(this, intent.getIntExtra(NewVideoNotifications.EXTRA_NOTIFICATION_ID, 0))
                SubscriptionChannel.requestDownload(
                    mapOf(
                        "videoId" to videoId,
                        "title" to intent.getStringExtra("title"),
                        "channelId" to intent.getStringExtra("channelId"),
                        "channelName" to intent.getStringExtra("channelName"),
                        "thumbnail" to intent.getStringExtra("thumbnail"),
                        // 앱이 뒤에 있었다면 받기를 시작한 뒤 다시 뒤로 보낸다.
                        "background" to !resumed,
                    ),
                )
            }
        }
    }

    override fun onResume() {
        super.onResume()
        resumed = true
    }

    override fun onPause() {
        resumed = false
        super.onPause()
    }

    // 엔진은 화면보다 오래 산다 ([MuloEngine]): 받기 · 미리 듣기가 최근 작업에서 밀어도 이어지게.
    override fun provideFlutterEngine(context: Context): FlutterEngine = MuloEngine.obtain(context)

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onDestroy() {
        super.onDestroy()
        if (MuloEngine.activity === this) MuloEngine.activity = null
        MuloEngine.releaseWhenIdle()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (MuloEngine.mediaStore?.onActivityResult(requestCode, resultCode) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
