package com.mulo.app

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.MergingMediaSource
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
@androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
class PreviewChannel(private val context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME) {
    private val main = Handler(Looper.getMainLooper())

    private var player: ExoPlayer? = null

    /** 아직 준비 중인 `play` 호출. 다른 호출로 끊기면 조용히 성공으로 닫는다. */
    private var pending: MethodChannel.Result? = null

    /** 재생을 시작한 뒤에 난 오류만 `failure`로 알린다 (준비 중 오류는 `play` 결과로 간다). */
    private var started = false

    /** 지금 듣는 곡 정보 (id · title · url · uploader · thumbnail). Dart가 `remember`로 적어 둔다. */
    private var meta: Map<String, Any?>? = null

    /**
     * 같은 곡의 영상 전용 플레이어 (소리 없음). 소리를 내는 [player]의 시계에 맞춰 돌고,
     * 화면은 [VideoSurfaceHub]의 텍스처로 나간다. 영상은 덤이라 실패해도 소리에는 영향이 없다.
     */
    private var videoPlayer: ExoPlayer? = null
    private var videoUrl: String? = null

    /** 지금 소리 플레이어가 틀고 있는 주소. 영상 주소가 이것과 같으면 소리가 섞인 형식이라 영상도 이 플레이어가 튼다. */
    private var playUrl: String? = null

    /** 소리 플레이어 자신이 영상 화면을 내고 있다 (소리가 섞인 형식 또는 합쳐 튼 영상, 싱크가 필요 없다). */
    private var muxedVideo = false

    /** 소리 플레이어에 합쳐 놓은 영상 전용 주소 (한 플레이어 · 한 시계). 영상을 꺼도 합친 채 두어 다시 켤 때 끊기지 않는다. */
    private var mergedVideoUrl: String? = null

    /** 합친 영상의 해독이 실패해 꺼졌다 (같은 주소로 다시 켜지 않는다). */
    private var mergedFailed = false

    /** 지금 소리를 틀고 있는 주소의 요청 헤더 (영상을 합칠 때 소리 소스를 같은 헤더로 다시 만든다). */
    private var playHeaders: Map<String, String> = emptyMap()

    /** 처음에는 소리보다 [START_AHEAD_MS] 앞 지점에서 멈춘 채 받아 두었다가, 소리가 거기 닿는 순간 튼다. */
    private var videoStartPending = false

    /** 영상이 소리보다 앞선 지점에서 기다리는 길이. 영상이 제때 준비되지 못하면 늘려 다시 맞춘다. */
    private var pendingLead = START_AHEAD_MS
    private var videoSpeed = 1f
    private var lastHardSeek = 0L

    /** 영상이 미리 듣기 소리가 아니라 메인 재생(임시 저장한 음원을 들을 때)의 시계를 따른다. */
    private var followMain = false

    private fun reference(): ExoPlayer? = if (followMain) PlaybackHub.mainPlayerOrNull() else player

    private val videoSync = object : Runnable {
        override fun run() {
            val v = videoPlayer ?: return
            val a = reference() ?: return
            syncVideo(v, a)
            main.postDelayed(this, SYNC_INTERVAL_MS)
        }
    }

    private var videoPreparedAt = 0L

    private val videoListener = object : Player.Listener {
        override fun onPlaybackStateChanged(state: Int) {
            val took = android.os.SystemClock.elapsedRealtime() - videoPreparedAt
            MuloLog.d(MuloLog.PLAYBACK, "미리 듣기 영상 상태 $state (준비 시작 후 ${took}ms)")
        }

        override fun onRenderedFirstFrame() {
            val took = android.os.SystemClock.elapsedRealtime() - videoPreparedAt
            MuloLog.d(MuloLog.PLAYBACK, "미리 듣기 영상 첫 화면 (준비 시작 후 ${took}ms)")
        }

        override fun onPlayerError(error: PlaybackException) {
            MuloLog.e(MuloLog.NATIVE, "미리 듣기 영상 오류: ${error.errorCodeName}", error)
            releaseVideo()
        }
    }

    private fun isVideoDecoderError(error: PlaybackException) =
        error.errorCode == PlaybackException.ERROR_CODE_DECODER_INIT_FAILED ||
            error.errorCode == PlaybackException.ERROR_CODE_DECODING_FAILED ||
            error.errorCode == PlaybackException.ERROR_CODE_DECODER_QUERY_FAILED ||
            error.errorCode == PlaybackException.ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES

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
            MuloLog.e(MuloLog.NATIVE, "미리 듣기 소리 오류: ${error.errorCodeName}", error)
            val p = player
            if (muxedVideo && p != null && isVideoDecoderError(error)) {
                // 영상 해독만 실패했다: 영상을 끄고 소리는 이어서 재생한다.
                muxedVideo = false
                if (mergedVideoUrl != null) mergedFailed = true
                VideoSurfaceHub.setPreviewVideo(null)
                p.trackSelectionParameters = p.trackSelectionParameters.buildUpon()
                    .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, true)
                    .build()
                p.prepare()
                p.play()
                return
            }
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
                "playVideo" -> {
                    val url = call.argument<String>("url")
                    if (url == null) {
                        result.error("bad_args", "url required", null)
                        return@setMethodCallHandler
                    }
                    playVideo(
                        url,
                        call.argument<Map<String, String>>("headers") ?: emptyMap(),
                        follow = call.argument<Boolean>("followMain") == true,
                    )
                    result.success(null)
                }
                "stopVideo" -> { releaseVideo(); result.success(null) }
                "seek" -> {
                    val ms = (call.arguments as Number).toLong()
                    player?.seekTo(ms)
                    // 소리와 영상이 따로 받아서 준비되는 때가 달라, 그냥 옮기면 한쪽이 먼저 달려 어긋난다.
                    // 영상은 소리보다 조금 앞에서 멈춘 채 받아 두었다가, 소리가 닿는 순간 함께 튼다 (처음 시작과 같은 방식).
                    videoPlayer?.let { v -> if (!muxedVideo) restartVideoAt(v, ms, SEEK_PENDING_LEAD_MS) }
                    result.success(null)
                }
                "pause" -> { player?.pause(); result.success(null) }
                "resume" -> { player?.play(); result.success(null) }
                "stop" -> { stop(); result.success(null) }
                "remember" -> {
                    @Suppress("UNCHECKED_CAST")
                    meta = call.arguments as? Map<String, Any?>
                    result.success(null)
                }
                "current" -> result.success(current())
                "enterPip" -> result.success((MuloEngine.activity as? MainActivity)?.enterPip() ?: false)
                "cacheInfo" -> result.success(
                    mapOf(
                        "usedBytes" to StreamCache.usedBytes(context),
                        "limitBytes" to StreamCache.limitBytes(context),
                        "savedBytes" to StreamCache.savedBytes(context),
                        "freeBytes" to context.filesDir.usableSpace,
                    ),
                )
                "setSaved" -> {
                    StreamCache.setSavedIds((call.argument<List<String>>("ids") ?: emptyList()).flatMap { it.split(",") })
                    result.success(null)
                }
                "saveStream" -> {
                    val id = call.argument<String>("id")
                    val streams = call.argument<List<Map<String, Any?>>>("streams")
                    val targets = streams?.mapNotNull { m ->
                        val url = m["url"] as? String ?: return@mapNotNull null
                        @Suppress("UNCHECKED_CAST")
                        url to ((m["headers"] as? Map<String, String>) ?: emptyMap())
                    }
                    if (id == null || targets.isNullOrEmpty()) {
                        result.error("bad_args", "id, streams required", null)
                        return@setMethodCallHandler
                    }
                    // 스트림 주소의 id(영상 id와 다르다)를 돌려준다: 이 값으로 보관 여부를 가르고 지운다.
                    // 영상 전용 + 소리 전용이면 주소마다 id가 다를 수 있어 쉼표로 이어 돌려준다.
                    // 주소에 id가 없는 곳(사운드클라우드 등)은 캐시 키를 id 대신 쓴다 (보관 여부 · 지우기가 같은 키로 맞는다).
                    val ids = targets.map { t ->
                        val u = Uri.parse(t.first)
                        u.getQueryParameter("id") ?: StreamCache.keyOf(u)
                    }.distinct()
                    ids.forEach { StreamCache.addSavedId(it) }
                    val streamId = if (ids.isEmpty()) null else ids.joinToString(",")
                    // 받는 일은 따로 돌고, 끝나면 Dart에 알린다.
                    StreamCache.fillSaved(
                        context,
                        id,
                        targets,
                        progress = { pct -> main.post { channel.invokeMethod("savedProgress", mapOf("id" to id, "percent" to pct)) } },
                    ) { ok ->
                        main.post { channel.invokeMethod("saved", mapOf("id" to id, "ok" to ok)) }
                    }
                    result.success(streamId)
                }
                "removeSaved" -> {
                    StreamCache.removeSaved(context, call.argument<String>("id") ?: "", call.argument<String>("streamId"))
                    result.success(null)
                }
                "setCacheLimit" -> {
                    // 열려 있는 저장소를 닫아야 해서 듣던 미리 듣기는 멈춘다.
                    stop()
                    StreamCache.setLimit(context, (call.arguments as Number).toLong())
                    result.success(null)
                }
                "clearCache" -> {
                    stop()
                    StreamCache.clear(context)
                    result.success(null)
                }
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
            .setMediaSourceFactory(DefaultMediaSourceFactory(context).setDataSourceFactory(StreamCache.wrap(context, http)))
            .setLoadControl(streamLoadControl())
            .setAudioAttributes(
                AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),
                true,
            )
            .setWakeMode(C.WAKE_MODE_NETWORK)
            .build()
        // 영상 해독은 화면(Dart)이 붙었을 때만 [VideoSurfaceHub]가 켠다. 소리만 쓰는 곡은 꺼 둔다.
        created.trackSelectionParameters = created.trackSelectionParameters.buildUpon()
            .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, true)
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
        playUrl = url
        playHeaders = headers
        p.setMediaItem(MediaItem.fromUri(Uri.parse(url)))
        p.playWhenReady = true
        p.prepare()
    }

    private fun playVideo(url: String, headers: Map<String, String>, follow: Boolean = false) {
        val audio = (if (follow) PlaybackHub.mainPlayerOrNull() else player) ?: return
        if (!follow && url == playUrl) {
            // 소리가 섞인 형식: 같은 플레이어가 소리와 영상을 한 시계로 튼다 (영상 전용 플레이어 · 맞추기 없음).
            if (!muxedVideo) {
                releaseVideo()
                muxedVideo = true
                VideoSurfaceHub.setPreviewVideo(audio)
                // 작은 창(PiP) 진입 조건 · 재생 버튼이 이 플레이어를 보게 한다 (빠뜨리면 PiP가 안 뜬다).
                VideoSurfaceHub.previewIsPlaying = { player?.isPlaying == true }
                VideoSurfaceHub.previewSetPlaying = { play -> if (play) player?.play() else player?.pause() }
            }
            return
        }
        // 메인 시계를 따르는 경우가 아니면 소리 플레이어에 영상을 합쳐 한 시계로 튼다 (싱크를 맞출 필요가 없다).
        if (!follow) {
            mergeVideo(audio, url, headers)
            return
        }
        if (videoUrl == url && videoPlayer != null && followMain == follow) return
        // 영상 전용 플레이어를 다른 화질로 바꿔 끼울 때: 화면을 비우지 않고 이전 화면을 둔 채 새 영상으로 넘어간다.
        val old = if (!muxedVideo && videoPlayer != null) videoPlayer else null
        if (old != null) {
            main.removeCallbacks(videoSync)
            old.removeListener(videoListener)
            videoPlayer = null
            videoUrl = null
        } else {
            releaseVideo()
        }
        followMain = follow
        val http = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)
        agentFor(url)?.let { http.setUserAgent(it) }
        val v = ExoPlayer.Builder(context)
            .setMediaSourceFactory(DefaultMediaSourceFactory(context).setDataSourceFactory(StreamCache.wrap(context, http)))
            .setLoadControl(streamLoadControl())
            // 소리는 다른 플레이어가 낸다: 오디오 포커스도 가져가지 않는다.
            .setAudioAttributes(AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).build(), false)
            .build()
        v.volume = 0f
        v.trackSelectionParameters = v.trackSelectionParameters.buildUpon()
            .setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, true)
            .build()
        v.addListener(videoListener)
        v.setMediaItem(MediaItem.fromUri(Uri.parse(url)))
        v.playWhenReady = false
        v.seekTo(audio.currentPosition + START_AHEAD_MS)
        videoPreparedAt = android.os.SystemClock.elapsedRealtime()
        v.prepare()
        videoPlayer = v
        videoUrl = url
        videoStartPending = true
        pendingLead = START_AHEAD_MS
        videoSpeed = 1f
        VideoSurfaceHub.setPreviewVideo(v, keepFrame = old != null)
        old?.release()
        if (follow) {
            VideoSurfaceHub.previewIsPlaying = { PlaybackHub.mainPlayerOrNull()?.isPlaying == true }
            VideoSurfaceHub.previewSetPlaying = { play -> if (play) PlaybackHub.play() else PlaybackHub.pause() }
        } else {
            VideoSurfaceHub.previewIsPlaying = { player?.isPlaying == true }
            VideoSurfaceHub.previewSetPlaying = { play -> if (play) player?.play() else player?.pause() }
        }
        main.post(videoSync)
    }

    /**
     * 영상 전용 주소를 소리 플레이어의 소스에 합친다 ([MergingMediaSource]). 소리와 영상이 한 플레이어의 한 시계로 돌아
     * 이동 · 화질 전환에도 어긋나지 않는다. 합치는 순간 지금 위치에서 다시 준비하느라 소리가 잠깐 끊길 수 있다.
     * 같은 영상이 이미 합쳐져 있으면 소스는 그대로 두고 화면만 다시 켠다.
     */
    private fun mergeVideo(a: ExoPlayer, url: String, headers: Map<String, String>) {
        if (mergedVideoUrl == url) {
            if (!muxedVideo && !mergedFailed) attachMerged(a)
            return
        }
        val audioUrl = playUrl ?: return
        val wasShowing = muxedVideo
        // 영상 전용 플레이어가 따로 돌고 있었다면 치운다.
        if (videoPlayer != null) releaseVideo()
        fun sourceOf(u: String, h: Map<String, String>): androidx.media3.exoplayer.source.MediaSource {
            val http = DefaultHttpDataSource.Factory()
                .setAllowCrossProtocolRedirects(true)
                .setDefaultRequestProperties(h)
            agentFor(u)?.let { http.setUserAgent(it) }
            return DefaultMediaSourceFactory(context)
                .setDataSourceFactory(StreamCache.wrap(context, http))
                .createMediaSource(MediaItem.fromUri(Uri.parse(u)))
        }
        val position = a.currentPosition
        val merged = MergingMediaSource(sourceOf(audioUrl, playHeaders), sourceOf(url, headers))
        mergedVideoUrl = url
        mergedFailed = false
        muxedVideo = true
        // 화질을 바꿀 때는 이전 화면을 둔 채 새 영상의 첫 화면이 그려지면 바뀐다.
        VideoSurfaceHub.setPreviewVideo(a, keepFrame = wasShowing)
        hookPreview()
        a.setMediaSource(merged, position)
        a.prepare()
        MuloLog.d(MuloLog.PLAYBACK, "미리 듣기 영상 합쳐 튼다 (위치 ${position}ms)")
    }

    /** 이미 합쳐 둔 영상의 화면을 다시 켠다. */
    private fun attachMerged(a: ExoPlayer) {
        muxedVideo = true
        VideoSurfaceHub.setPreviewVideo(a)
        hookPreview()
    }

    /** 작은 창(PiP) 진입 조건 · 재생 버튼이 소리 플레이어를 보게 한다 (빠뜨리면 PiP가 안 뜬다). */
    private fun hookPreview() {
        VideoSurfaceHub.previewIsPlaying = { player?.isPlaying == true }
        VideoSurfaceHub.previewSetPlaying = { play -> if (play) player?.play() else player?.pause() }
    }

    /** 소리의 시계에 영상을 맞춘다. 되감지 않고 재생 속도를 아주 조금 바꿔 따라잡는다 (되감으면 끊겨 보인다). */
    private fun syncVideo(v: ExoPlayer, a: ExoPlayer) {
        if (videoStartPending) {
            if (!a.playWhenReady) {
                // 소리가 멈춰 있으면 그 자리의 첫 화면만 보여 준다.
                v.seekTo(a.currentPosition)
                v.playWhenReady = false
                videoStartPending = false
                return
            }
            if (v.playbackState != Player.STATE_READY) return
            val ahead = v.currentPosition - a.currentPosition
            if (ahead > START_TOLERANCE_MS) return // 소리가 아직 거기 닿지 않았다
            if (ahead < -START_MISSED_MS) {
                // 영상이 준비되는 사이 소리가 지나갔다: 더 앞에서 다시 받아 두고 기다린다 (바로 틀면 늘 뒤처진다).
                restartVideoAt(v, a.currentPosition, (pendingLead * 2).coerceAtMost(MAX_PENDING_LEAD_MS))
                return
            }
            v.playWhenReady = true
            videoStartPending = false
            return
        }
        if (v.playWhenReady != a.playWhenReady) v.playWhenReady = a.playWhenReady
        if (v.playbackState == Player.STATE_BUFFERING || a.playbackState == Player.STATE_BUFFERING) return
        // 양수면 영상이 소리보다 앞서 있다.
        val drift = v.currentPosition - a.currentPosition
        val now = SystemClock.elapsedRealtime()
        if (kotlin.math.abs(drift) > HARD_SEEK_MS) {
            // 크게 벌어졌다: 속도를 바꿔 따라가면 오래 걸리니, 소리가 닿을 때 함께 트는 방식으로 다시 맞춘다.
            if (now - lastHardSeek > HARD_SEEK_GAP_MS) {
                lastHardSeek = now
                restartVideoAt(v, a.currentPosition, RESYNC_LEAD_MS)
            }
            return
        }
        val abs = kotlin.math.abs(drift)
        if (videoSpeed != 1f) {
            // 거의 맞았거나 반대로 넘어갔으면 원래 속도로.
            if (abs < SETTLE_MS || (drift > 0) == (videoSpeed > 1f)) setVideoSpeed(v, 1f)
        } else if (abs > ENGAGE_MS) {
            setVideoSpeed(v, if (drift > 0) SLOW_DOWN else CATCH_UP)
        }
    }

    /** 영상을 소리 위치 [audioMs]보다 [lead] 앞에서 멈춘 채 받아 두고, 소리가 닿으면 함께 틀도록 되돌린다. */
    private fun restartVideoAt(v: ExoPlayer, audioMs: Long, lead: Long) {
        pendingLead = lead
        videoSpeed = 1f
        v.setPlaybackSpeed(1f)
        v.playWhenReady = false
        v.seekTo(audioMs + lead)
        videoStartPending = true
    }

    private fun setVideoSpeed(v: ExoPlayer, speed: Float) {
        if (videoSpeed == speed) return
        videoSpeed = speed
        v.setPlaybackSpeed(speed)
    }

    private fun releaseVideo() {
        main.removeCallbacks(videoSync)
        // 합쳐 둔 영상은 소스는 두고 영상 해독만 끈다 (화면이 없는데 해독하지 않게).
        if (muxedVideo && mergedVideoUrl != null) {
            player?.let { p ->
                p.trackSelectionParameters = p.trackSelectionParameters.buildUpon()
                    .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, true)
                    .build()
            }
        }
        VideoSurfaceHub.setPreviewVideo(null)
        VideoSurfaceHub.previewIsPlaying = null
        VideoSurfaceHub.previewSetPlaying = null
        videoPlayer?.removeListener(videoListener)
        videoPlayer?.release()
        videoPlayer = null
        videoUrl = null
        videoStartPending = false
        muxedVideo = false
        followMain = false
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
        releaseVideo()
        main.removeCallbacks(ticker)
        player?.removeListener(listener)
        player?.release()
        player = null
        playUrl = null
        mergedVideoUrl = null
        mergedFailed = false
        started = false
        meta = null
    }

    /**
     * 스트리밍 버퍼 설정. 기본값은 이동한 뒤 2.5초(끊긴 뒤 5초) 쌓여야 틀어서 느린 연결에서 오래 멈춘다.
     * 이동 · 끊김 뒤에는 조금만 쌓이면 바로 틀고(0.5초 · 1.5초), 재생 중에는 최대 90초까지 미리 받아 둔다.
     */
    private fun streamLoadControl() = DefaultLoadControl.Builder()
        .setBufferDurationsMs(
            /* minBufferMs = */ 30_000,
            /* maxBufferMs = */ 90_000,
            /* bufferForPlaybackMs = */ 500,
            /* bufferForPlaybackAfterRebufferMs = */ 1_500,
        )
        .build()

    /** 주소를 만든 클라이언트(`c=`)와 같은 user-agent. 모르는 클라이언트면 null (기본값). */
    private fun agentFor(url: String): String? = when (Uri.parse(url).getQueryParameter("c")) {
        "ANDROID" -> "com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip"
        "VISIONOS" -> "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 " +
            "(KHTML, like Gecko) Version/26.0 Safari/605.1.15"
        else -> null
    }

    override fun dispose() {
        stop()
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/preview"

        /** 영상 맞추기: 시작할 때 소리보다 앞 지점에서 기다리는 길이, 따라잡기 속도, 되감기 기준 (ms). */
        private const val START_AHEAD_MS = 1500L
        private const val START_TOLERANCE_MS = 60L
        private const val START_MISSED_MS = 300L
        private const val SYNC_INTERVAL_MS = 40L
        private const val ENGAGE_MS = 100L
        private const val SETTLE_MS = 40L
        private const val HARD_SEEK_MS = 700L
        private const val HARD_SEEK_GAP_MS = 1500L
        private const val SEEK_PENDING_LEAD_MS = 700L
        private const val RESYNC_LEAD_MS = 600L
        private const val MAX_PENDING_LEAD_MS = 4000L
        private const val CATCH_UP = 1.06f
        private const val SLOW_DOWN = 0.94f
    }
}
