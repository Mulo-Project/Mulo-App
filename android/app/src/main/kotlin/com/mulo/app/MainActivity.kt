package com.mulo.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// 생체 인증(local_auth)이 FragmentActivity를 요구한다.
class MainActivity : FlutterFragmentActivity() {
    private var mediaStore: MediaStoreChannel? = null
    private var lyrics: LyricsChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStore = MediaStoreChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        lyrics = LyricsChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        mediaStore?.dispose()
        mediaStore = null
        lyrics?.dispose()
        lyrics = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
