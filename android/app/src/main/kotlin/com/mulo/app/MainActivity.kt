package com.mulo.app

import android.content.Intent
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// 생체 인증(local_auth)이 FragmentActivity를 요구한다. 재생 알림(audio_service)은 같은 엔진을 서비스와 나눠 쓴다.
class MainActivity : AudioServiceFragmentActivity() {
    private val downloadActionIds = setOf("preview", "stopPreview", "pausePreview", "cancel")
    private var mediaStore: MediaStoreChannel? = null
    private var lyrics: LyricsChannel? = null
    private var audioOutput: AudioOutputChannel? = null
    private var ytDlp: YtDlpChannel? = null
    private var transcoder: TranscoderChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStore = MediaStoreChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger) { this }
        lyrics = LyricsChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        audioOutput = AudioOutputChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        ytDlp = YtDlpChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        transcoder = TranscoderChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sendBackIfDownloadAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        sendBackIfDownloadAction(intent)
    }

    // 받기 알림의 버튼(미리듣기 · 중지 · 취소)은 앱 쪽에서 처리하려고 화면을 거치지만, 화면은 곧바로 뒤로 보낸다.
    private fun sendBackIfDownloadAction(intent: Intent?) {
        val id = intent?.getStringExtra("actionId") ?: return
        if (intent.action == "SELECT_NOTIFICATION" && id in downloadActionIds) moveTaskToBack(true)
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
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
