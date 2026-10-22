package com.mulo.app

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * 앱의 Flutter 엔진을 화면(MainActivity)과 따로 쥔다. 받기와 미리 듣기는 Dart가 이 엔진 안에서 하므로,
 * 최근 작업에서 화면을 밀어도 포그라운드 서비스(받기) · 미리 듣기 알림이 떠 있는 동안은 엔진을 살려 둔다.
 * 그런 일이 없고 화면도 없으면 엔진을 정리한다. 채널은 엔진과 같은 수명이고, 화면이 필요한 일은 [activity]로 한다.
 */
object MuloEngine {
    /** 엔진 캐시 이름. 화면(Fragment)은 새 엔진이 아니라 캐시의 이 엔진을 써야 화면이 닫혀도 엔진이 같이 죽지 않는다. */
    const val CACHE_ID = "mulo_engine"

    private val main = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private var channels: List<() -> Unit> = emptyList()

    /** 지금 떠 있는 화면 (없으면 null). */
    @Volatile
    var activity: Activity? = null

    var mediaStore: MediaStoreChannel? = null
        private set

    /** 화면 없이도 엔진을 살려 둬야 하는지: 받기 서비스가 붙들고 있거나 미리 듣기가 알림에 떠 있을 때. */
    private fun needed() = DownloadForegroundService.wanted || PlaybackHub.isPreviewing

    fun obtain(context: Context): FlutterEngine {
        engine?.let { return it }
        val app = context.applicationContext
        val created = FlutterEngine(app)
        GeneratedPluginRegistrant.registerWith(created)
        // 받기 알림은 화면이 아니라 엔진에 묶는다 (화면이 닫혀도 버튼이 Dart로 전달된다).
        created.plugins.add(DownloadNotificationPlugin())
        val messenger = created.dartExecutor.binaryMessenger
        val store = MediaStoreChannel(app, messenger) { activity }
        val lyrics = LyricsChannel(app, messenger)
        val lyricsOverlay = LyricsOverlayChannel(app, messenger)
        val audioOutput = AudioOutputChannel(app, messenger)
        val ytDlp = YtDlpChannel(app, messenger)
        val transcoder = TranscoderChannel(app, messenger)
        val playback = PlaybackChannel(app, messenger)
        val equalizer = EqualizerChannel(app, messenger)
        val subscriptions = SubscriptionChannel(app, messenger) { activity?.moveTaskToBack(true) }
        mediaStore = store
        channels = listOf(
            store::dispose, lyrics::dispose, lyricsOverlay::dispose, audioOutput::dispose, ytDlp::dispose,
            transcoder::dispose, playback::dispose, equalizer::dispose, subscriptions::dispose,
        )
        engine = created
        FlutterEngineCache.getInstance().put(CACHE_ID, created)
        // 캐시된 엔진은 화면(Fragment)이 Dart를 시작해 주지 않으므로, 채널을 다 붙인 뒤 여기서 시작한다.
        created.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        return created
    }

    /** 잠시 뒤 확인해서, 화면도 붙들 일도 없으면 엔진을 정리한다 (받기 끝 · 미리 듣기 끝 · 화면 닫힘 뒤). */
    fun releaseWhenIdle() {
        main.postDelayed({
            if (activity == null && !needed()) release()
        }, 3000)
    }

    private fun release() {
        val current = engine ?: return
        engine = null
        FlutterEngineCache.getInstance().remove(CACHE_ID)
        channels.forEach { it() }
        channels = emptyList()
        mediaStore = null
        // 미리 듣기 소리는 엔진과 함께 끝나므로 알림에 남은 미리 듣기도 치운다.
        if (PlaybackHub.isPreviewing) PlaybackHub.setSession(null)
        current.destroy()
    }
}
