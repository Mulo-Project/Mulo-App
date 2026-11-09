package com.mulo.app

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.util.Rational
import androidx.core.content.ContextCompat
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
        LyricsOverlay.setAppVisible(true)
    }

    override fun onPause() {
        resumed = false
        // 작은 창(PiP)은 앱이 보이는 것으로 친다 (가사 창이 영상 위에 겹치지 않게).
        LyricsOverlay.setAppVisible(inPip())
        super.onPause()
    }

    override fun onStop() {
        if (!resumed) LyricsOverlay.setAppVisible(false)
        super.onStop()
    }

    // 영상이 나오는 중에 홈으로 나가면 영상을 작은 창(PiP)으로 띄운다 (Android 8+).
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || inPip()) return
        val size = VideoSurfaceHub.pipSize() ?: return
        try {
            enterPictureInPictureMode(pipParams(size.first, size.second, VideoSurfaceHub.isPlaying()))
        } catch (e: IllegalStateException) {
            MuloLog.e(MuloLog.NATIVE, "PiP 진입 실패: ${e.message}", e)
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        if (isInPictureInPictureMode) {
            ContextCompat.registerReceiver(this, pipReceiver, IntentFilter(ACTION_PIP_TOGGLE), ContextCompat.RECEIVER_NOT_EXPORTED)
            pipReceiverRegistered = true
            LyricsOverlay.setAppVisible(true)
        } else {
            unregisterPipReceiver()
            LyricsOverlay.setAppVisible(resumed)
        }
        VideoSurfaceHub.emit?.invoke("pip", mapOf("value" to isInPictureInPictureMode))
    }

    private fun inPip(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInPictureInPictureMode

    private var pipReceiverRegistered = false

    /** 작은 창의 재생 · 일시정지 버튼. */
    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val play = !VideoSurfaceHub.isPlaying()
            VideoSurfaceHub.setPlaying(play)
            val size = VideoSurfaceHub.videoSize() ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                setPictureInPictureParams(pipParams(size.first, size.second, play))
            }
        }
    }

    private fun unregisterPipReceiver() {
        if (!pipReceiverRegistered) return
        pipReceiverRegistered = false
        unregisterReceiver(pipReceiver)
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.O)
    private fun pipParams(width: Int, height: Int, playing: Boolean): PictureInPictureParams {
        // 가로세로 비율은 시스템 허용 범위(약 2.39:1 ~ 1:2.39) 안으로.
        val ratio = (width.toDouble() / height).coerceIn(1.0 / 2.39, 2.39)
        val label = if (playing) "일시정지" else "재생"
        val action = RemoteAction(
            Icon.createWithResource(
                this,
                if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
            ),
            label,
            label,
            PendingIntent.getBroadcast(
                this,
                0,
                Intent(ACTION_PIP_TOGGLE).setPackage(packageName),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            ),
        )
        return PictureInPictureParams.Builder()
            .setAspectRatio(Rational((ratio * 10000).toInt(), 10000))
            .setActions(listOf(action))
            .build()
    }

    // 엔진은 화면보다 오래 산다 ([MuloEngine]): 받기 · 미리 듣기가 최근 작업에서 밀어도 이어지게.
    override fun provideFlutterEngine(context: Context): FlutterEngine = MuloEngine.obtain(context)

    // 새 엔진을 만드는 Fragment는 화면과 함께 엔진을 destroy한다(provideFlutterEngine과 상관없이).
    // 캐시된 엔진으로 붙여야 shouldDestroyEngineWithHost(false)가 먹는다.
    override fun getCachedEngineId(): String {
        MuloEngine.obtain(this)
        return MuloEngine.CACHE_ID
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onDestroy() {
        unregisterPipReceiver()
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

    companion object {
        private const val ACTION_PIP_TOGGLE = "com.mulo.app.PIP_TOGGLE"
    }
}
