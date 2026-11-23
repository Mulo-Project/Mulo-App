package com.mulo.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.view.TextureRegistry

/**
 * 영상 화면(텍스처) 연결 (`music_app/video`). 소리와 영상은 네이티브 플레이어가 한 시계로 다루고
 * ([VideoSurfaceHub]), Dart는 `attach`로 받은 텍스처를 그리기만 한다.
 *
 * Dart → 네이티브: `attach`(텍스처 id · 지금 상태를 돌려준다) · `detach`(화면이 영상을 더는 안 본다).
 * 네이티브 → Dart: `size`(width, height) · `ready`(value: 첫 화면이 그려졌는지).
 */
class VideoChannel(context: Context, messenger: BinaryMessenger, private val textures: TextureRegistry) :
    NativeChannel(messenger, NAME) {
    init {
        VideoSurfaceHub.emit = { method, args -> channel.invokeMethod(method, args) }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "attach" -> result.success(VideoSurfaceHub.attach(textures))
                "detach" -> {
                    VideoSurfaceHub.detach()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispose() {
        VideoSurfaceHub.shutdown()
        super.dispose()
    }

    companion object {
        const val NAME = "music_app/video"
    }
}
