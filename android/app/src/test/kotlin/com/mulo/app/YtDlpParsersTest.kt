package com.mulo.app

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class YtDlpParsersTest {
    private fun j(s: String) = JSONObject(s)

    // org.json(JVM 쪽)은 키 순서를 지키지 않아서, 순서가 뜻을 갖지 않는 목록은 정렬해 비교한다.
    private fun sorted(v: Any?) = (v as List<*>).map { it.toString() }.sorted()

    @Test
    fun hitReadsFieldsAndFallsBack() {
        val h = YtDlpParsers.hit(
            j(
                """{"id":"abc12345678","title":"T","uploader":"U","duration":100.4,"webpage_url":"https://w",
                "channel_url":"https://c","view_count":12.0,"upload_date":"20240131","description":" d ",
                "like_count":5,"channel_follower_count":9,"creators":["A"," ",3],"album":"Al",
                "categories":["Music"," ",3]}""",
            ),
        )
        assertEquals("https://w", h["url"])
        assertEquals(100, h["seconds"])
        assertEquals(12L, h["views"])
        assertEquals("2024-01-31", h["uploadDate"])
        assertEquals("d", h["description"])
        assertEquals(5L, h["likes"])
        assertEquals(9L, h["subscribers"])
        assertEquals(listOf("A"), h["creators"])
        assertEquals(listOf("Music"), h["categories"])
        assertEquals("Al", h["album"])
        assertEquals(false, h["isLive"])
    }

    @Test
    fun hitEmptyFieldsAndLive() {
        val h = YtDlpParsers.hit(j("""{"id":"a","title":"Ta"}"""))
        assertEquals(emptyList<String>(), h["categories"])
        assertEquals("", h["uploader"])
        assertEquals("https://www.youtube.com/watch?v=a", h["url"])
        assertNull(h["seconds"])
        assertEquals(false, h["isLive"]) // 길이가 없어도 id가 11자가 아니면 라이브로 보지 않는다
        // 유튜브 id(11자)인데 길이가 없으면 라이브 · 예정 방송
        assertEquals(true, YtDlpParsers.hit(j("""{"id":"abc12345678","title":"T"}"""))["isLive"])
        assertEquals(true, YtDlpParsers.hit(j("""{"id":"x","live_status":"is_upcoming","duration":5}"""))["isLive"])
    }

    @Test
    fun thumbnailPicksLargestUnder500() {
        val t = YtDlpParsers.thumbnailOf(
            j("""{"thumbnails":[{"url":"s","width":100},{"url":"m","width":400},{"url":"big","width":2000}]}"""),
        )
        assertEquals("m", t)
        assertEquals("last", YtDlpParsers.thumbnailOf(j("""{"thumbnails":[{"url":"a"},{"url":"last"}]}""")))
        assertEquals("direct", YtDlpParsers.thumbnailOf(j("""{"thumbnail":"direct","thumbnails":[{"url":"x"}]}""")))
    }

    @Test
    fun translatedAutoCaptionsAreDropped() {
        fun track(lang: String, translated: Boolean) =
            "\"$lang\":[{\"url\":\"https://yt/api/timedtext?v=1${if (translated) "&tlang=$lang" else ""}\"}]"
        val raw = j("{" + listOf(track("ja-orig", false), track("ko", true), track("mk", true)).joinToString(",") + "}")
        assertEquals(listOf("ja-orig"), YtDlpParsers.originalAutoKeys(raw))
        val h = YtDlpParsers.hit(j("""{"id":"v","title":"T","subtitles":{"ko":[],"live_chat":[]},"automatic_captions":{"en-orig":[]}}"""))
        assertEquals(listOf("en-orig", "ko"), sorted(h["subtitleLangs"]))
        assertEquals(listOf("en-orig"), h["autoSubtitleLangs"])
    }

    @Test
    fun playlistHit() {
        val p = YtDlpParsers.playlistHit(
            j("""{"id":"PL1","title":"L","url":"https://www.youtube.com/playlist?list=PL1","uploader":"C","playlist_count":7}"""),
        )!!
        assertEquals("PL1", p["id"])
        assertEquals("C", p["channel"])
        assertEquals(7L, p["trackCount"])
        assertNull(YtDlpParsers.playlistHit(j("""{"id":"v","url":"https://www.youtube.com/watch?v=v"}""")))
        assertEquals("PLx", YtDlpParsers.playlistHit(j("""{"url":"https://y/p?list=PLx&a=1"}"""))!!["id"])
    }

    @Test
    fun infoPlaylistOrVideo() {
        val p = YtDlpParsers.info(j("""{"_type":"playlist","title":"L","entries":[{"id":"a","title":"Ta"}]}"""))
        assertEquals("playlist", p["type"])
        assertEquals(1, (p["entries"] as List<*>).size)
        assertEquals("video", YtDlpParsers.info(j("""{"id":"v","title":"T"}"""))["type"])
    }

    @Test
    fun channelAvatarSkipsBanner() {
        val c = YtDlpParsers.channel(
            j(
                """{"channel_follower_count":1234,"thumbnails":[{"id":"0","url":"banner"},
                {"id":"avatar_1","url":"a1"},{"id":"avatar_uncropped","url":"full"}]}""",
            ),
        )
        assertEquals("full", c["thumbnail"])
        assertEquals(1234L, c["subscriberCount"])
        assertNull(YtDlpParsers.channel(j("""{"thumbnails":[{"id":"0","url":"b"}]}"""))["thumbnail"])
    }

    @Test
    fun audioAndVideoStreams() {
        val a = YtDlpParsers.audio(j("""{"url":"https://a","http_headers":{"User-Agent":"x","n":3}}"""))!!
        assertEquals("https://a", a["url"])
        assertEquals(mapOf("User-Agent" to "x"), a["headers"])
        assertNull(YtDlpParsers.audio(j("""{"id":"x"}""")))
        assertTrue(YtDlpParsers.video(j("""{"url":"u","vcodec":"avc1","acodec":"mp4a"}"""))!!["muxed"] as Boolean)
        assertFalse(YtDlpParsers.video(j("""{"url":"u","vcodec":"avc1","acodec":"none"}"""))!!["muxed"] as Boolean)
    }

    @Test
    fun audioLanguagesNeedTwoOrMore() {
        val two = YtDlpParsers.audioLanguages(
            j(
                """{"formats":[{"vcodec":"none","language":"en","format_note":"English (US) original (default), medium"},
                {"vcodec":"none","language":"ko","format_note":"Korean, medium"},{"vcodec":"avc1","language":"fr"}]}""",
            ),
        )
        assertEquals(listOf("en", "ko"), two.map { it["id"] })
        assertEquals("English (US)", two[0]["name"])
        assertEquals(true, two[0]["isDefault"])
        assertEquals(false, two[1]["isDefault"])
        val one = YtDlpParsers.audioLanguages(j("""{"formats":[{"vcodec":"none","language":"en"}]}"""))
        assertTrue(one.isEmpty())
    }

    @Test
    fun failureCodes() {
        assertEquals("not_found", YtDlpParsers.failureCode("ERROR: Unsupported URL: x"))
        assertEquals("network", YtDlpParsers.failureCode("Unable to download webpage"))
        assertEquals("failed", YtDlpParsers.failureCode("boom"))
    }

    @Test
    fun subtitleLanguagePick() {
        assertEquals("en" to false, YtDlpParsers.pickSubtitleLanguage(listOf("ja", "en"), listOf("ko-orig"), listOf("ko", "en")))
        assertEquals("ko-orig" to true, YtDlpParsers.pickSubtitleLanguage(emptyList(), listOf("en", "ko-orig"), listOf("en")))
        assertEquals("ko-KR" to false, YtDlpParsers.pickSubtitleLanguage(listOf("ko-KR"), emptyList(), listOf("ko")))
        assertNull(YtDlpParsers.pickSubtitleLanguage(emptyList(), emptyList(), listOf("ko")))
    }

    @Test
    fun vttDropsTagsAndRepeatedLines() {
        val vtt = "WEBVTT\nKind: captions\n\n00:00:01.000 --> 00:00:03.000\n첫 줄\n\n" +
            "00:00:03.000 --> 00:00:05.000\n첫 줄\n<c>둘째</c> 줄\n\n00:01:05.500 --> 00:01:07.000\n&amp; 셋째\n"
        val cues = YtDlpParsers.parseVtt(vtt)
        assertEquals(listOf("첫 줄", "둘째 줄", "& 셋째"), cues.map { it["text"] })
        assertEquals(65500L, cues.last()["ms"])
        assertEquals(1000L, cues.first()["ms"])
    }

    @Test
    fun selectors() {
        assertEquals("bestaudio[ext=webm]/bestaudio[protocol^=http]/bestaudio/best", YtDlpParsers.audioSelector(null))
        assertTrue(YtDlpParsers.audioSelector("ko").startsWith("bestaudio[language=ko][ext=webm]/"))
        assertTrue(YtDlpParsers.videoSelector(360).startsWith("b[height<=360]"))
        assertTrue(YtDlpParsers.videoSelector(720).startsWith("bv[height<=720]"))
        assertTrue(YtDlpParsers.saveSelector(1080, "webm").contains("[ext=webm]"))
        assertTrue(YtDlpParsers.saveSelector(1080, "mp4").contains("[vcodec^=avc1]+ba[ext=m4a]"))
    }

    @Test
    fun soundcloudAvatarFromOgImage() {
        val html = """<html><head><meta property="og:title" content="Artist">
            <meta property="og:image" content="https://i1.sndcdn.com/avatars-000-abc-large.jpg?x=1&amp;y=2"></head></html>"""
        assertEquals("https://i1.sndcdn.com/avatars-000-abc-t500x500.jpg?x=1&y=2", YtDlpParsers.soundcloudAvatarFromHtml(html))
        assertNull(YtDlpParsers.soundcloudAvatarFromHtml("<html></html>"))
        assertTrue(YtDlpParsers.isSoundcloud("https://soundcloud.com/artist"))
        assertTrue(YtDlpParsers.isSoundcloud("https://m.soundcloud.com/artist"))
        assertFalse(YtDlpParsers.isSoundcloud("https://www.youtube.com/@a"))
    }
}
