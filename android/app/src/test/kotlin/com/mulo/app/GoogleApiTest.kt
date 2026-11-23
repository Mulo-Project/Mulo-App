package com.mulo.app

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class GoogleApiTest {
    @Test
    fun playlistFields() {
        val hit = GoogleApi.parsePlaylist(
            JSONObject(
                """{"id":"PL1","snippet":{"title":"운동","channelTitle":"나",
                "thumbnails":{"default":{"url":"small"},"medium":{"url":"mid"}}},"contentDetails":{"itemCount":7}}""",
            ),
        )!!
        assertEquals("운동", hit["title"])
        assertEquals("나", hit["channel"])
        assertEquals(7, hit["trackCount"])
        assertEquals("mid", hit["thumbnail"])
        assertEquals("https://www.youtube.com/playlist?list=PL1", hit["url"])
        assertNull(GoogleApi.parsePlaylist(JSONObject("""{"snippet":{}}""")))
    }

    @Test
    fun subscriptionFields() {
        val hit = GoogleApi.parseSubscription(
            JSONObject(
                """{"snippet":{"title":"채널","description":"소개",
                "resourceId":{"kind":"youtube#channel","channelId":"UC1"},
                "thumbnails":{"default":{"url":"small"},"medium":{"url":"mid"}}}}""",
            ),
        )!!
        assertEquals("UC1", hit["id"])
        assertEquals("채널", hit["name"])
        assertEquals("소개", hit["description"])
        assertEquals("mid", hit["thumbnail"])
        assertNull(GoogleApi.parseSubscription(JSONObject("""{"snippet":{}}""")))
    }

    @Test
    fun errorDetailReadsReasonAndMessage() {
        assertEquals(
            "quotaExceeded over quota",
            GoogleApi.errorDetail("""{"error":{"errors":[{"reason":"quotaExceeded"}],"message":"over quota"}}"""),
        )
        assertEquals("", GoogleApi.errorDetail("<html>"))
    }
}
