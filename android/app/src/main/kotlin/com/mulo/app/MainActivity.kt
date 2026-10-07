package com.mulo.app

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// 생체 인증(local_auth)이 FragmentActivity를 요구한다. 재생 알림(audio_service)은 같은 엔진을 서비스와 나눠 쓴다.
class MainActivity : AudioServiceFragmentActivity() {
    private var mediaStore: MediaStoreChannel? = null
    private var lyrics: LyricsChannel? = null
    private var audioOutput: AudioOutputChannel? = null
    private var ytDlp: YtDlpChannel? = null
    private var transcoder: TranscoderChannel? = null

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
