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
        return MergingMediaSource(base.createMediaSource(MediaItem.fromUri(video)), audio)
    }

    companion object {
        const val VIDEO_URI = "videoUri"
    }
}
