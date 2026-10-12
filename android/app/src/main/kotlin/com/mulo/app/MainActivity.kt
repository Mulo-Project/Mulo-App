package com.mulo.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// 생체 인증(local_auth)이 FragmentActivity를 요구한다. 재생 · 알림은 PlaybackHub(서비스)가 쥐고 PlaybackChannel로 이어진다.
class MainActivity : FlutterFragmentActivity() {
    private var playback: PlaybackChannel? = null
    private var equalizer: EqualizerChannel? = null
    private var mediaStore: MediaStoreChannel? = null
    private var lyrics: LyricsChannel? = null
    private var audioOutput: AudioOutputChannel? = null
    private var ytDlp: YtDlpChannel? = null
    private var transcoder: TranscoderChannel? = null
    private var subscriptions: SubscriptionChannel? = null

    /** 화면에 떠 있는지. 새 인텐트가 들어올 때 앱이 뒤에 있었는지 알려고 쓴다. */
    private var resumed = false

    override fun onCreate(savedInstanceState: Bundle?) {
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 받기 알림은 화면이 아니라 엔진에 묶는다 (화면이 닫혀도 버튼이 Dart로 전달된다).
        if (!flutterEngine.plugins.has(DownloadNotificationPlugin::class.java)) {
            flutterEngine.plugins.add(DownloadNotificationPlugin())
        }
        mediaStore = MediaStoreChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger) { this }
        lyrics = LyricsChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        audioOutput = AudioOutputChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        ytDlp = YtDlpChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        transcoder = TranscoderChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        playback = PlaybackChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        equalizer = EqualizerChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        subscriptions = SubscriptionChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger) {
            moveTaskToBack(true)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (mediaStore?.onActivityResult(requestCode, resultCode) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        mediaStore?.dispose()
        mediaStore = null
        lyrics?.dispose()
        lyrics = null
        audioOutput?.dispose()
        audioOutput = null
        ytDlp?.dispose()
        ytDlp = null
        transcoder?.dispose()
        transcoder = null
        playback?.dispose()
        playback = null
        equalizer?.dispose()
        equalizer = null
        subscriptions?.dispose()
        subscriptions = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
