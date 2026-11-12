package com.mulo.app

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class YoutubePlaylistParseTest {
    private fun nodes(json: String): List<JSONObject> {
        val out = ArrayList<JSONObject>()
        YoutubeBrowser.collectPlaylistNodes(JSONObject(json), out)
        return out
    }

    @Test
    fun findsOldAndNewShapesAndContinuationAnywhere() {
        val root = """{"a":{"b":[{"x":{"contents":[
            {"playlistVideoRenderer":{"videoId":"v1","title":{"runs":[{"text":"옛 모양"}]},"lengthSeconds":"65"}},
            {"lockupViewModel":{"contentType":"LOCKUP_CONTENT_TYPE_VIDEO","contentId":"v2",
              "metadata":{"lockupMetadataViewModel":{"title":{"content":"새 모양"},
                "metadata":{"contentMetadataViewModel":{"metadataRows":[{"metadataParts":[{"text":{"content":"채널"}}]}]}}}},
              "contentImage":{"thumbnailViewModel":{"image":{"sources":[{"url":"s"},{"url":"big"}]},
                "overlays":[{"thumbnailBottomOverlayViewModel":{"badges":[{"thumbnailBadgeViewModel":{"text":"1:02:03"}}]}}]}}}},
            {"lockupViewModel":{"contentType":"LOCKUP_CONTENT_TYPE_PLAYLIST","contentId":"PL"}},
            {"continuationItemRenderer":{"continuationEndpoint":{"continuationCommand":{"token":"T"}}}}]}}]}}"""
        val found = nodes(root)
        assertEquals(3, found.size) // 재생목록 lockup은 곡이 아니다
        val old = YoutubeBrowser.parsePlaylistVideo(found[0].optJSONObject("playlistVideoRenderer"))!!
        assertEquals("v1", old.id)
        assertEquals(65, old.seconds)
        val new = YoutubeBrowser.parsePlaylistLockup(found[1].optJSONObject("lockupViewModel"))!!
        assertEquals("v2", new.id)
        assertEquals("새 모양", new.title)
        assertEquals("채널", new.uploader)
        assertEquals("big", new.thumbnail)
        assertEquals(3723, new.seconds)
        assertEquals("T", YoutubeBrowser.continuationToken(found[2]))
        assertNull(YoutubeBrowser.parsePlaylistLockup(null))
    }
}
