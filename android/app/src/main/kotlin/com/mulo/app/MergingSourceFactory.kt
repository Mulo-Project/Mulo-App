package com.mulo.app

import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.drm.DrmSessionManagerProvider
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.MergingMediaSource
import androidx.media3.exoplayer.upstream.LoadErrorHandlingPolicy

/**
 * 곡에 영상 전용 주소(`videoUri`)가 붙어 있으면 소리 소스와 영상 소스를 합쳐 한 플레이어가 한 시계로 튼다.
 * 임시 저장한 영상은 소리와 영상이 따로 저장되기 때문이다. 영상 주소가 없으면 평소와 같다.
 */
@OptIn(UnstableApi::class)
internal class MergingSourceFactory(private val base: MediaSource.Factory) : MediaSource.Factory {
    override fun setDrmSessionManagerProvider(provider: DrmSessionManagerProvider): MediaSource.Factory {
        base.setDrmSessionManagerProvider(provider)
        return this
    }

    override fun setLoadErrorHandlingPolicy(policy: LoadErrorHandlingPolicy): MediaSource.Factory {
        base.setLoadErrorHandlingPolicy(policy)
        return this
    }

    override fun getSupportedTypes(): IntArray = base.supportedTypes

    override fun createMediaSource(mediaItem: MediaItem): MediaSource {
        val audio = base.createMediaSource(mediaItem)
        val video = mediaItem.mediaMetadata.extras?.getString(VIDEO_URI)
        if (video.isNullOrEmpty()) return audio
        // 합친 소스의 곡 정보(id · 제목 · 부가 정보)는 첫 소스의 MediaItem을 따른다. 소리 소스를 앞에 둬야
        // 대기열의 id가 비지 않는다 (영상 소스를 앞에 두면 id가 ""가 되어 앱이 대기열 갱신을 무시한다).
        return MergingMediaSource(audio, base.createMediaSource(MediaItem.fromUri(video)))
    }

    companion object {
        const val VIDEO_URI = "videoUri"
    }
}
