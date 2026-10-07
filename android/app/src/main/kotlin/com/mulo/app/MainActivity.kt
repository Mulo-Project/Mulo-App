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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStore = MediaStoreChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger) { this }
        lyrics = LyricsChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        audioOutput = AudioOutputChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        ytDlp = YtDlpChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
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
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
