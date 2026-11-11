package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class YoutubeFormatsTest {
    private fun audio(itag: Int, mime: String, bitrate: Long, track: String? = null, default: Boolean = false) = YtFormat(
        itag, "u$itag", mime, bitrate, 0, 1000, false, track, track?.let { "n-$it" }, default,
    )

    private fun video(itag: Int, height: Int, muxed: Boolean, mime: String = "video/mp4; codecs=\"avc1\"") =
        YtFormat(itag, "u$itag", mime, 1, height, 1000, muxed)

    @Test
    fun languageIdDropsTrackSuffix() {
        assertEquals("en-US", YoutubeFormats.languageId("en-US.4"))
        assertEquals("ko", YoutubeFormats.languageId("ko"))
    }

    @Test
    fun audioPrefersContainerThenBitrate() {
        val all = listOf(
            audio(1, "audio/mp4; codecs=\"mp4a\"", 128),
            audio(2, "audio/webm; codecs=\"opus\"", 50),
            audio(3, "audio/webm; codecs=\"opus\"", 160),
            video(4, 360, true),
        )
        assertEquals(listOf(3, 2, 1), YoutubeFormats.orderAudio(all, true, null).map { it.itag })
        assertEquals(listOf(1, 3, 2), YoutubeFormats.orderAudio(all, false, null).map { it.itag })
    }

    @Test
    fun audioFiltersByLanguage() {
        val all = listOf(
            audio(1, "audio/webm", 100, "ko.4", true),
            audio(2, "audio/webm", 90, "en-US.4"),
        )
        assertEquals(listOf(2), YoutubeFormats.orderAudio(all, true, "en-US").map { it.itag })
        assertTrue(YoutubeFormats.orderAudio(all, true, "ja").isEmpty())
    }

    @Test
    fun videoPicksMuxedWhenNotSmallerThanVideoOnly() {
        val all = listOf(video(1, 360, true), video(2, 360, false), video(3, 720, false))
        val (best, muxed) = YoutubeFormats.pickVideo(all, 360)!!
        assertEquals(1, best.itag)
        assertTrue(muxed)
    }

    @Test
    fun videoPicksLargerVideoOnlyWithinLimit() {
        val all = listOf(video(1, 360, true), video(3, 720, false), video(4, 1080, false))
        val (best, muxed) = YoutubeFormats.pickVideo(all, 720)!!
        assertEquals(3, best.itag)
        assertFalse(muxed)
    }

    @Test
    fun videoIgnoresNonMp4VideoOnlyAndReturnsNullWhenNone() {
        val all = listOf(video(1, 720, false, "video/webm; codecs=\"vp9\""))
        assertNull(YoutubeFormats.pickVideo(all, 720))
    }

    @Test
    fun languagesDedupeByIdKeepingOrder() {
        val all = listOf(
            audio(1, "audio/webm", 1, "ko.4", true),
            audio(2, "audio/webm", 1, "ko.4", true),
            audio(3, "audio/webm", 1, "en-US.4"),
        )
        assertEquals(listOf("ko", "en-US"), YoutubeFormats.languages(all).map { it.first })
    }
}
