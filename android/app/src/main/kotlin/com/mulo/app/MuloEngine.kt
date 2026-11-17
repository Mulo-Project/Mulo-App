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
 * 앱의 Flutter 엔진을 화면(MainActivity)과 따로 쥔다. 받기는 Dart가 이 엔진 안에서 하고 미리 듣기 소리는 PreviewChannel이 내므로,
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

    /** 미리 듣기 소리 (받기 알림의 미리 듣기 버튼이 앱 화면 없이 바로 부른다). */
    var preview: PreviewChannel? = null
        private set

    /** 받기 큐(네이티브). 알림 버튼 수신기가 앱 화면 없이 바로 부른다. */
    var downloads: DownloadEngine? = null
        private set

    /** 엔진이 이미 떠 있는가 (화면이 새로 열릴 때, 엔진이 화면보다 오래 살아 있었는지 알려고). */
    fun isAlive() = engine != null

    private var appSession: io.flutter.plugin.common.MethodChannel? = null

    /** 화면이 새로 열렸는데 엔진(앱 상태)은 그대로 살아 있었다: 밀어 닫았다 다시 켠 것이다. 앱 잠금이 다시 잠그게 알린다. */
    fun notifyRelaunched() {
        appSession?.invokeMethod("relaunched", null)
    }

    /** 화면 없이도 엔진을 살려 둬야 하는지: 받기 서비스가 붙들고 있거나 미리 듣기가 알림에 떠 있을 때. */
    private fun needed() = DownloadForegroundService.wanted || PlaybackHub.isPreviewing || (downloads?.isBusy() == true)

    fun obtain(context: Context): FlutterEngine {
        engine?.let { return it }
        val app = context.applicationContext
        MuloLog.init(app)
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
        val ytDlpEngine = YtDlpEngineChannel(app, messenger, ytDlp, transcoder::mux)
        val youtubeResolve = YoutubeResolveChannel(app, messenger)
        val googleApi = GoogleApiChannel(app, messenger)
        val tags = TagChannel(app, messenger, store, transcoder)
        val playback = PlaybackChannel(app, messenger)
        val preview = PreviewChannel(app, messenger)
        val video = VideoChannel(app, messenger, created.renderer)
        val equalizer = EqualizerChannel(app, messenger)
        val subscriptions = SubscriptionChannel(app, messenger) { activity?.moveTaskToBack(true) }
        val downloadChannel = DownloadChannel(app, messenger, ytDlpEngine.engine, transcoder, store, tags)
        downloads = downloadChannel.engine
        this.preview = preview
        mediaStore = store
        appSession = io.flutter.plugin.common.MethodChannel(messenger, "music_app/app_session")
        channels = listOf(
            store::dispose, lyrics::dispose, lyricsOverlay::dispose, audioOutput::dispose, ytDlp::dispose, ytDlpEngine::dispose,
            transcoder::dispose, playback::dispose, preview::dispose, video::dispose, equalizer::dispose,
            subscriptions::dispose, youtubeResolve::dispose, googleApi::dispose, tags::dispose, downloadChannel::dispose,
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
        downloads = null
        preview = null
        appSession = null
        // 미리 듣기 소리는 엔진과 함께 끝나므로 알림에 남은 미리 듣기도 치운다.
        MuloLog.d(MuloLog.PLAYBACK, "엔진 정리: 미리듣기알림=${PlaybackHub.isPreviewing}")
        if (PlaybackHub.isPreviewing) PlaybackHub.setSession(null)
        current.destroy()
    }
}
