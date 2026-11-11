package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class YoutubeChannelParsersTest {
    // 유튜브 채널 페이지 안의 데이터는 \x22 같은 이스케이프로 들어 있다 (주소는 예시).
    private val page =
        """names \x22imageBannerViewModel\x22,\x22dynamicTextViewModel\x22 ... """ +
            """imageBannerViewModel\x22:\x7b\x22image\x22:\x7b\x22sources\x22:\x5b\x7b""" +
            """\x22url\x22:\x22https:\/\/yt3.googleusercontent.com\/abc\x3dw1060-k\x22,""" +
            """\x22width\x22:1060\x7d \x22content\x22:\x22@x • 1.91M subscribers\x22"""

    @Test
    fun bannerUrlFromPage() {
        assertEquals("https://yt3.googleusercontent.com/abc=w1060-k", YoutubeChannelParsers.bannerUrl(page))
        assertNull(YoutubeChannelParsers.bannerUrl("<html></html>"))
    }

    @Test
    fun descriptionIsUnescaped() {
        val html = """"channelMetadataRenderer":{"title":"Lofi \"Girl\"","description":""" +
            """"첫 줄\n둘째 줄 \"인용\" 🌇\n","rssUrl":"https://example.com"}"""
        assertEquals("첫 줄\n둘째 줄 \"인용\" 🌇", YoutubeChannelParsers.description(html))
        assertNull(YoutubeChannelParsers.description("<html></html>"))
        assertNull(YoutubeChannelParsers.description(""""channelMetadataRenderer":{"title":"x","description":"   "}"""))
    }

    @Test
    fun subscriberCount() {
        assertEquals(1910000L, YoutubeChannelParsers.subscriberCount(page))
        assertEquals(532L, YoutubeChannelParsers.subscriberCount("532 subscribers"))
        assertNull(YoutubeChannelParsers.subscriberCount("nothing"))
    }

    @Test
    fun channelIdFromPage() {
        assertEquals(
            "UCaaaaaaaaaaaaaaaaaaaaaa",
            YoutubeChannelParsers.channelIdFromPage("""{"externalId":"UCaaaaaaaaaaaaaaaaaaaaaa"}"""),
        )
        assertNull(YoutubeChannelParsers.channelIdFromPage("<html></html>"))
    }

    @Test
    fun feedReadsEntriesAndSkipsBroken() {
        val xml = """<feed>
 <entry>
  <yt:videoId>AAA11111111</yt:videoId>
  <title>Song &amp; Dance &#39;26</title>
  <published>2026-10-11T10:00:00+00:00</published>
  <author><name>Some Channel</name></author>
  <media:group>
   <media:thumbnail url="https://i.ytimg.com/vi/AAA11111111/hqdefault.jpg" width="480" height="360"/>
   <media:community><media:statistics views="1234"/></media:community>
  </media:group>
 </entry>
 <entry>
  <yt:videoId>BBB22222222</yt:videoId>
  <title>Older</title>
  <published>2026-10-01T10:00:00+00:00</published>
 </entry>
 <entry><title>Broken, no id</title></entry>
</feed>"""
        val videos = YoutubeChannelParsers.feed(xml)
        assertEquals(listOf("AAA11111111", "BBB22222222"), videos.map { it.id })
        val first = videos.first()
        assertEquals("Song & Dance '26", first.title)
        assertEquals(1791712800000L, first.publishedMs)
        assertEquals("Some Channel", first.author)
        assertEquals(1234L, first.views)
        assertEquals("", videos[1].author)
    }
}
