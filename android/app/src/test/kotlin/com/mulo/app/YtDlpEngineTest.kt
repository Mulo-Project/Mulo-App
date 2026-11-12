package com.mulo.app

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class YtDlpEngineTest {
    @get:Rule val tmp = TemporaryFolder()

    private class Fake(
        override val available: Boolean = true,
        val handler: (List<String>) -> YtDlpRun,
    ) : YtDlpRunner {
        val calls = ArrayList<List<String>>()
        var cancelled = ArrayList<String>()

        override fun run(args: List<String>, id: String, onProgress: ((Double) -> Unit)?): YtDlpRun {
            calls.add(args)
            return handler(args)
        }

        override fun cancel(id: String): Boolean = cancelled.add(id)
    }

    private fun ok(out: String) = YtDlpRun(0, out, "")
    private fun engine(r: Fake, timeoutMs: Long = 5000) = YtDlpEngine(r, { File(tmp.root, "sub") }, timeoutMs)

    private fun line(id: String) = JSONObject(mapOf("id" to id, "title" to "T$id", "uploader" to "U", "duration" to 100.0)).toString()

    private fun code(block: () -> Unit): String {
        try {
            block()
        } catch (e: YtDlpException) {
            return e.code
        }
        fail("no exception")
        return ""
    }

    @Test
    fun searchTakesPageTimesSizeAndSlices() {
        val r = Fake { ok("${line("a")}\n${line("b")}\n${line("c")}\n") }
        val page = engine(r).search("ytsearch", "노래", 1, 2)
        assertEquals("ytsearch4:노래", r.calls.last().last())
        assertEquals(listOf("c"), (page["items"] as List<*>).map { (it as Map<*, *>)["id"] })
        assertEquals(false, page["hasNext"])
        engine(r).search("scsearch", "노래", 0, 1)
        assertEquals("scsearch1:노래", r.calls.last().last())
        engine(r).search("ytsearchdate", "노래", 0, 3)
        assertEquals("ytsearchdate3:노래", r.calls.last().last())
    }

    @Test
    fun searchPlaylistsReadsCounts() {
        val r = Fake { ok(JSONObject(mapOf("id" to "PL1", "title" to "L", "url" to "https://www.youtube.com/playlist?list=PL1", "playlist_count" to 7)).toString() + "\n") }
        val page = engine(r).searchPlaylists("q", 0, 20)
        val item = (page["items"] as List<*>).single() as Map<*, *>
        assertEquals("PL1", item["id"])
        assertEquals(7L, item["trackCount"])
        assertTrue(r.calls.last().contains("--playlist-end"))
    }

    @Test
    fun infoSkipsDashAndHls() {
        val r = Fake { ok("""{"id":"v","title":"T"}""") }
        engine(r).info("https://x/v")
        val a = r.calls.last()
        assertTrue(a.containsAll(listOf("--extractor-args", "youtube:skip=dash,hls,translated_subs")))
    }

    @Test
    fun audioFallsBackToAndroidVrThenReportsFirstError() {
        var n = 0
        val r = Fake {
            n++
            if (n == 1) YtDlpRun(1, "", "first failure") else ok("""{"url":"https://a","http_headers":{"A":"b"}}""")
        }
        val a = engine(r).audio("https://x", null)
        assertEquals("https://a", a["url"])
        assertTrue(r.calls.last().contains("youtube:player_client=android_vr"))
        assertEquals("-f", r.calls.first()[0])

        val bad = Fake { YtDlpRun(1, "", "first failure") }
        val e = try {
            engine(bad).audio("https://x", null)
            null
        } catch (e: YtDlpException) {
            e
        }
        assertEquals("failed", e!!.code)
        assertEquals("first failure", e.message)
    }

    @Test
    fun missingUrlIsFailure() {
        val r = Fake { ok("""{"id":"x"}""") }
        assertEquals("failed", code { engine(r).audio("https://x", null) })
    }

    @Test
    fun timeoutCancelsTheProcess() {
        val r = Fake {
            Thread.sleep(2000)
            ok("{}")
        }
        assertEquals("timeout", code { engine(r, 100).search("ytsearch", "q", 0, 1) })
        assertEquals(1, r.cancelled.size)
    }

    @Test
    fun unavailableRunner() {
        val r = Fake(available = false) { ok("") }
        assertFalse(engine(r).available)
        assertEquals("unavailable", code { engine(r).search("ytsearch", "q", 0, 1) })
    }

    @Test
    fun stderrDecidesFailureKind() {
        assertEquals("not_found", code { engine(Fake { YtDlpRun(1, "", "ERROR: Unsupported URL: x") }).info("x") })
        assertEquals("network", code { engine(Fake { YtDlpRun(1, "", "Unable to download webpage") }).info("x") })
    }

    @Test
    fun subtitlesPickOneLanguageAndReadFile() {
        val vtt = "WEBVTT\n\n00:00:01.000 --> 00:00:03.000\n첫 줄\n"
        val r = Fake { args ->
            if (args.contains("--dump-single-json")) {
                ok("""{"subtitles":{"en":[],"live_chat":[]},"automatic_captions":{"ko-orig":[]}}""")
            } else {
                val out = args[args.indexOf("-o") + 1]
                File("$out.en.vtt").writeText(vtt)
                ok("")
            }
        }
        val t = engine(r).subtitles("https://youtu.be/x", listOf("ko", "en"))!!
        assertEquals("en", t["language"])
        assertEquals(false, t["automatic"])
        assertEquals(1, (t["cues"] as List<*>).size)
        assertTrue(r.calls.last().containsAll(listOf("--write-subs", "--sub-langs", "en")))
        assertFalse(File(tmp.root, "sub").exists()) // 임시 폴더는 지운다
    }

    @Test
    fun noSubtitlesMeansNoDownload() {
        val r = Fake { ok("""{"subtitles":{},"automatic_captions":{}}""") }
        assertNull(engine(r).subtitles("https://youtu.be/x", listOf("ko")))
        assertEquals(1, r.calls.size)
    }

    @Test
    fun saveVideoUsesFormatSelectorAndMergeFormat() {
        val r = Fake { ok("") }
        engine(r).saveVideo("https://x", 720, "webm", tmp.root, "stem") {}
        val a = r.calls.last()
        assertEquals("webm", a[a.indexOf("--merge-output-format") + 1])
        assertTrue(a[a.indexOf("-f") + 1].contains("[ext=webm]"))
        assertTrue(a[a.indexOf("-o") + 1].endsWith("stem.%(ext)s"))
        val bad = Fake { YtDlpRun(1, "", "no space") }
        assertEquals("failed", code { engine(bad).saveVideo("https://x", 720, "mp4", tmp.root, "s") {} })
    }

    private val avatarPage = """<meta property="og:image" content="https://i1.sndcdn.com/avatars-000-abc-large.jpg">"""

    @Test
    fun soundcloudChannelFillsMissingAvatarFromPage() {
        val r = Fake { ok("""{"channel_follower_count":12}""") }
        val e = YtDlpEngine(r, { File(tmp.root, "sub") }, 5000, 5000, { avatarPage })
        val c = e.channel("https://soundcloud.com/artist")
        assertTrue((c["thumbnail"] as String).contains("t500x500"))
        assertEquals(12L, c["subscriberCount"])
    }

    @Test
    fun soundcloudAvatarIsReadEvenWhenYtDlpFails() {
        val r = Fake { YtDlpRun(1, "", "boom") }
        val e = YtDlpEngine(r, { File(tmp.root, "sub") }, 5000, 5000, { avatarPage })
        assertTrue((e.channel("https://soundcloud.com/artist")["thumbnail"] as String).isNotEmpty())
        val none = YtDlpEngine(r, { File(tmp.root, "sub") }, 5000, 5000, { null })
        assertEquals("failed", code { none.channel("https://soundcloud.com/artist") })
    }

    @Test
    fun otherSitesNeverReadThePage() {
        val r = Fake { ok("""{"thumbnails":[{"id":"avatar_1","url":"a"}]}""") }
        val e = YtDlpEngine(r, { File(tmp.root, "sub") }, 5000, 5000, { fail("페이지를 읽으면 안 된다"); null })
        assertEquals("a", e.channel("https://www.youtube.com/@a")["thumbnail"])
        val noAvatar = Fake { ok("""{"thumbnails":[]}""") }
        val e2 = YtDlpEngine(noAvatar, { File(tmp.root, "sub") }, 5000, 5000, { fail("페이지를 읽으면 안 된다"); null })
        assertNull(e2.channel("https://www.youtube.com/@a")["thumbnail"])
    }
}
