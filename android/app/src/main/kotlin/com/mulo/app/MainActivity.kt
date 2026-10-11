package com.mulo.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// 생체 인증(local_auth)이 FragmentActivity를 요구한다. 재생 · 알림은 PlaybackHub(서비스)가 쥐고 PlaybackChannel로 이어진다.
class MainActivity : FlutterFragmentActivity() {
    private var playback: PlaybackChannel? = null
    private var mediaStore: MediaStoreChannel? = null
    private var lyrics: LyricsChannel? = null
    private var audioOutput: AudioOutputChannel? = null
    private var ytDlp: YtDlpChannel? = null
    private var transcoder: TranscoderChannel? = null

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
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
