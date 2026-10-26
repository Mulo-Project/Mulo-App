package com.mulo.app

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * 미리 듣기 소리 (검색 결과 · 영상 상세에서 받지 않고 바로 듣기). 메인 재생([PlaybackHub])의 ExoPlayer와는 따로
 * 하나를 두고, 대기열 · 미니 플레이어에 끼어들지 않는다. 알림은 Dart가 `setSession`으로 계속 띄운다.
 *
 * Dart → 네이티브: `play`(url, headers) · `seek` · `pause` · `resume` · `stop`.
 * 앱이 꺼졌다 켜져도 Dart가 상태를 되살릴 수 있게 `remember`(듣는 곡 정보)로 곡을 적어 두고, `current`로 읽는다.
 * `current`는 소리를 내는 플레이어가 없으면 null을 돌려주고, 알림에 남은 미리 듣기도 함께 치운다.
 * 네이티브 → Dart: `completed` · `progress`(position, duration, ms) · `failure`(까닭).
 * `play`는 소리를 낼 준비가 되면 성공으로 돌려주고, 열지 못하면 `failed` 오류로 돌려준다.
 */
class PreviewChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)
    private val main = Handler(Looper.getMainLooper())

    private var player: ExoPlayer? = null

    /** 아직 준비 중인 `play` 호출. 다른 호출로 끊기면 조용히 성공으로 닫는다. */
    private var pending: MethodChannel.Result? = null

    /** 재생을 시작한 뒤에 난 오류만 `failure`로 알린다 (준비 중 오류는 `play` 결과로 간다). */
    private var started = false

    /** 지금 듣는 곡 정보 (id · title · url · uploader · thumbnail). Dart가 `remember`로 적어 둔다. */
    private var meta: Map<String, Any?>? = null

    private val ticker = object : Runnable {
        override fun run() {
            val p = player ?: return
            if (p.isPlaying) {
                channel.invokeMethod(
                    "progress",
                    mapOf(
                        "position" to p.currentPosition,
                        "duration" to if (p.duration == C.TIME_UNSET) null else p.duration,
                    ),
                )
            }
            main.postDelayed(this, 250)
        }
    }

    private val listener = object : Player.Listener {
        override fun onPlaybackStateChanged(state: Int) {
            when (state) {
                Player.STATE_READY -> {
                    started = true
                    pending?.success(null)
                    pending = null
                }
                Player.STATE_ENDED -> channel.invokeMethod("completed", null)
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            val message = "${error.errorCodeName}: ${error.message ?: ""}"
            val waiting = pending
            if (waiting != null) {
                pending = null
                waiting.error("failed", message, null)
            } else if (started) {
                channel.invokeMethod("failure", message)
            }
        }
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val url = call.argument<String>("url")
                    if (url == null) {
                        result.error("bad_args", "url required", null)
                        return@setMethodCallHandler
                    }
                    play(url, call.argument<Map<String, String>>("headers") ?: emptyMap(), result)
                }
                "seek" -> { player?.seekTo((call.arguments as Number).toLong()); result.success(null) }
                "pause" -> { player?.pause(); result.success(null) }
                "resume" -> { player?.play(); result.success(null) }
                "stop" -> { stop(); result.success(null) }
                "remember" -> {
                    @Suppress("UNCHECKED_CAST")
                    meta = call.arguments as? Map<String, Any?>
                    result.success(null)
                }
                "current" -> result.success(current())
                else -> result.notImplemented()
            }
        }
    }

    private fun ensure(headers: Map<String, String>, url: String): ExoPlayer {
        // 주소마다 요청 헤더 · user-agent가 달라서 재생마다 새 플레이어를 만든다 (미리 듣기는 한 곡씩이다).
        release()
        val http = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)
        agentFor(url)?.let { http.setUserAgent(it) }
        val created = ExoPlayer.Builder(context)
            .setMediaSourceFactory(DefaultMediaSourceFactory(context).setDataSourceFactory(http))
            .setLoadControl(DefaultLoadControl())
            .setAudioAttributes(
                AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),
                true,
            )
            .setWakeMode(C.WAKE_MODE_NETWORK)
            .build()
        created.addListener(listener)
        main.post(ticker)
        player = created
        return created
    }

    private fun play(url: String, headers: Map<String, String>, result: MethodChannel.Result) {
        // 진행 중이던 호출은 새 곡으로 바뀌었으니 조용히 닫는다.
        pending?.success(null)
        pending = result
        started = false
        val p = ensure(headers, url)
        p.setMediaItem(MediaItem.fromUri(Uri.parse(url)))
        p.playWhenReady = true
        p.prepare()
    }

    /** 소리를 내고 있는(또는 잠시 멈춘) 미리 듣기. 없으면 null이고, 알림에 남은 미리 듣기는 치운다. */
    private fun current(): Map<String, Any?>? {
        val p = player
        if (p == null) {
            // 소리는 없는데 미리 듣기 알림만 남았으면 눌러도 동작하지 않으므로 치운다.
            if (PlaybackHub.isPreviewing) PlaybackHub.setSession(null)
            return null
        }
        // 아직 불러오는 중이면 Dart가 시작한 `play`가 끝나면서 상태를 알리므로 읽을 것이 없다.
        if (!started) return null
        return (meta ?: emptyMap()) + mapOf(
            "positionMs" to p.currentPosition,
            "durationMs" to if (p.duration == C.TIME_UNSET) null else p.duration,
            "paused" to !p.playWhenReady,
        )
    }

    private fun stop() {
        pending?.success(null)
        pending = null
        release()
    }

    private fun release() {
        main.removeCallbacks(ticker)
        player?.removeListener(listener)
        player?.release()
        player = null
        started = false
        meta = null
    }

    /** 주소를 만든 클라이언트(`c=`)와 같은 user-agent. 모르는 클라이언트면 null (기본값). */
    private fun agentFor(url: String): String? = when (Uri.parse(url).getQueryParameter("c")) {
        "ANDROID" -> "com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip"
        "VISIONOS" -> "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 " +
            "(KHTML, like Gecko) Version/26.0 Safari/605.1.15"
        else -> null
    }

    fun dispose() {
        stop()
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val NAME = "music_app/preview"
    }
}
