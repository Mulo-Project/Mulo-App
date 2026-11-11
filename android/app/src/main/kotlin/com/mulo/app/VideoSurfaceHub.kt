package com.mulo.app

import android.os.Handler
import android.os.Looper
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.exoplayer.ExoPlayer
import io.flutter.view.TextureRegistry

/**
 * 영상 화면을 Flutter에 내보내는 텍스처 하나를 쥔다. 소리와 영상은 네이티브 플레이어가 한 시계로 다루고,
 * Dart는 이 텍스처를 `Texture` 위젯으로 그리기만 한다 (미니 플레이어 · 상세 화면 · 플레이어가 같은 텍스처를 나눠 쓴다).
 *
 * 텍스처를 받는 플레이어는 [previewVideo](미리 듣기의 영상 전용 플레이어)가 있으면 그것, 없으면 [mainPlayer](보관함 재생).
 * 화면(Dart)이 붙어 있을 때만 영상 해독을 켜서, 앱 화면이 없으면 영상 때문에 더 쓰지 않는다 (소리는 그대로).
 * 모든 호출은 메인 스레드.
 */
object VideoSurfaceHub {
    private var producer: TextureRegistry.SurfaceProducer? = null
    private var attached = false
    private var mainPlayer: ExoPlayer? = null
    private var previewVideo: ExoPlayer? = null
    private var bound: ExoPlayer? = null
    private var firstFrame = false
    private var width = 0
    private var height = 0

    /** 미리 듣기의 소리 플레이어는 [PreviewChannel]이 쥔다: PiP 버튼이 재생 상태를 읽고 바꾸는 통로. */
    var previewIsPlaying: (() -> Boolean)? = null
    var previewSetPlaying: ((Boolean) -> Unit)? = null

    /** Dart로 알린다 (`size` · `ready` · `pip`). 채널이 붙으면 채운다. */
    var emit: ((String, Map<String, Any?>) -> Unit)? = null

    private val playerListener = object : Player.Listener {
        override fun onVideoSizeChanged(videoSize: VideoSize) = sizeChanged(videoSize)

        override fun onRenderedFirstFrame() {
            firstFrame = true
            emit?.invoke("ready", mapOf("value" to true))
        }
    }

    /** 화면이 영상을 보려 한다: 텍스처를 만들고 지금 상태를 돌려준다 (`id` · `ready` · `width` · `height`). */
    fun attach(registry: TextureRegistry): Map<String, Any?> {
        val p = producer ?: registry.createSurfaceProducer().also {
            it.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                override fun onSurfaceAvailable() = refresh()
                override fun onSurfaceCleanup() {
                    bound?.clearVideoSurface()
                }
            })
            producer = it
        }
        attached = true
        refresh()
        return mapOf("id" to p.id(), "ready" to firstFrame, "width" to width, "height" to height)
    }

    /** 화면이 더는 영상을 보지 않는다: 영상 해독을 끈다 (소리는 그대로). */
    fun detach() {
        attached = false
        refresh()
    }

    /** 소리가 나는 중인지 (영상이 보이는 곡 기준). */
    fun isPlaying(): Boolean =
        if (previewVideo != null) previewIsPlaying?.invoke() == true else mainPlayer?.isPlaying == true

    fun setPlaying(play: Boolean) {
        if (previewVideo != null) previewSetPlaying?.invoke(play)
        else if (play) PlaybackHub.play() else PlaybackHub.pause()
    }

    /**
     * 작은 창(PiP)으로 보낼 만한 영상이 있으면 영상 크기(width, height), 없으면 null.
     * 영상이 화면에 붙어 첫 화면이 그려졌을 때만 (일시정지 중이어도 작은 창으로 보낸다: 창에는 재생 버튼이 뜬다).
     */
    fun pipSize(): Pair<Int, Int>? =
        if (attached && firstFrame && width > 0 && height > 0) width to height else null

    /** PiP에 안 들어가는 까닭을 로그로 남기려고: 진입 조건 각각의 지금 값. */
    fun pipDebug(): String =
        "attached=$attached firstFrame=$firstFrame size=${width}x$height playing=${isPlaying()} " +
            "preview=${previewVideo != null} main=${mainPlayer != null}"

    /** 지금 영상 크기. 아직 모르면 null. */
    fun videoSize(): Pair<Int, Int>? = if (width > 0 && height > 0) width to height else null

    fun setMain(player: ExoPlayer?) {
        mainPlayer = player
        refresh()
    }

    /** [keepFrame]: 영상 플레이어만 바꿔 끼운다 (화질 전환). 이전 화면을 그대로 두고 새 영상의 첫 화면이 그려지면 바뀐다. */
    fun setPreviewVideo(player: ExoPlayer?, keepFrame: Boolean = false) {
        previewVideo = player
        refresh(keepFrame && player != null && bound != null)
    }

    fun shutdown() {
        attached = false
        bound?.let {
            it.removeListener(playerListener)
            it.clearVideoSurface()
        }
        bound = null
        mainPlayer?.let { setVideoDisabled(it, true) }
        producer?.release()
        producer = null
        emit = null
    }

    private fun setVideoDisabled(player: ExoPlayer, disabled: Boolean) {
        val params = player.trackSelectionParameters
        if (params.disabledTrackTypes.contains(C.TRACK_TYPE_VIDEO) == disabled) return
        player.trackSelectionParameters = params.buildUpon()
            .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, disabled)
            .build()
    }

    private fun refresh(keepFrame: Boolean = false) {
        val target = if (attached) (previewVideo ?: mainPlayer) else null
        if (bound !== target) {
            bound?.let {
                it.removeListener(playerListener)
                it.clearVideoSurface()
            }
            bound = target
            target?.addListener(playerListener)
            if (!keepFrame) {
                firstFrame = false
                width = 0
                height = 0
                emit?.invoke("ready", mapOf("value" to false))
            }
        }
        // 표면이 유효할 때만 영상 해독을 켠다 (표면 없이 켜면 해독기 초기화가 실패해 소리까지 멈춘다).
        val surface = producer?.surface
        val ready = surface != null && surface.isValid
        mainPlayer?.let { setVideoDisabled(it, target !== it || !ready) }
        previewVideo?.let { setVideoDisabled(it, target !== it || !ready) }
        if (target != null && surface != null && ready) {
            target.setVideoSurface(surface)
            sizeChanged(target.videoSize)
        }
    }

    private fun sizeChanged(size: VideoSize) {
        if (size.width <= 0 || size.height <= 0) return
        val w = (size.width * size.pixelWidthHeightRatio).toInt().coerceAtLeast(1)
        width = w
        height = size.height
        producer?.setSize(w, size.height)
        emit?.invoke("size", mapOf("width" to w, "height" to size.height))
    }
}
