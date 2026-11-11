package com.mulo.app

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.time.OffsetDateTime

/**
 * 유튜브 채널 관련 읽기를 네이티브에서 한다: 채널 페이지(배너 · 소개 · 구독자 수 · 이미지), 채널 id 알아내기, 채널 RSS 피드.
 * 페이지 · 피드를 읽는 글 모양 해석은 [YoutubeChannelParsers] (순수 함수, 단위 테스트).
 */
object YoutubeChannels {
    private const val TAG = MuloLog.NATIVE
    private const val PAGE_UA = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Mobile Safari/537.36"

    /** 채널 상세: bannerUrl · logoUrl · subscriberCount · description (읽은 것만 담긴다). */
    fun details(channelId: String): Map<String, Any?> {
        val start = System.currentTimeMillis()
        val html = getText("https://www.youtube.com/channel/$channelId", cookie = "CONSENT=YES+1; SOCS=CAI")
        MuloLog.d(TAG, "채널 상세 ${System.currentTimeMillis() - start}ms")
        return mapOf(
            "bannerUrl" to YoutubeChannelParsers.bannerUrl(html),
            "logoUrl" to YoutubeChannelParsers.logoUrl(html),
            "subscriberCount" to YoutubeChannelParsers.subscriberCount(html),
            "description" to YoutubeChannelParsers.description(html),
        )
    }

    /** 채널 주소에서 채널 id(`UC…`)를 알아낸다. 유튜브 주소가 아니거나 못 찾으면 null. */
    fun resolveChannelId(channelUrl: String): String? {
        val url = try {
            URL(channelUrl.trim())
        } catch (e: Exception) {
            return null
        }
        if (!url.host.endsWith("youtube.com")) return null
        val segments = url.path.split('/').filter { it.isNotEmpty() }
        val at = segments.indexOf("channel")
        if (at >= 0 && at + 1 < segments.size) {
            val id = segments[at + 1]
            if (YoutubeChannelParsers.isChannelId(id)) return id
        }
        // 핸들(@이름) · 사용자 이름 주소는 채널 페이지에서 채널 id를 읽는다.
        return YoutubeChannelParsers.channelIdFromPage(getText(url.toString(), cookie = "CONSENT=YES+1; SOCS=CAI"))
    }

    /** 채널 RSS의 최근 영상들: id · title · publishedMs · author · thumbnail? · views?. */
    fun feed(channelId: String): List<Map<String, Any?>> {
        val start = System.currentTimeMillis()
        val xml = getText("https://www.youtube.com/feeds/videos.xml?channel_id=$channelId")
        val videos = YoutubeChannelParsers.feed(xml).map { v ->
            mapOf(
                "id" to v.id, "title" to v.title, "publishedMs" to v.publishedMs,
                "author" to v.author, "thumbnail" to v.thumbnail, "views" to v.views,
            )
        }
        MuloLog.d(TAG, "채널 피드 ${videos.size}개 ${System.currentTimeMillis() - start}ms")
        return videos
    }

    private fun getText(url: String, cookie: String? = null): String {
        val conn = URL(url).openConnection() as HttpURLConnection
        var ok = false
        try {
            conn.connectTimeout = 10_000
            conn.readTimeout = 20_000
            conn.setRequestProperty("User-Agent", PAGE_UA)
            conn.setRequestProperty("Accept-Language", "en-US,en;q=0.8")
            if (cookie != null) conn.setRequestProperty("Cookie", cookie)
            val code = conn.responseCode
            if (code != 200) throw IOException("HTTP $code")
            val text = conn.inputStream.bufferedReader().use { it.readText() }
            ok = true
            return text
        } finally {
            if (!ok) conn.disconnect()
        }
    }
}

/** 채널 페이지 · 피드의 글을 읽는 순수 함수들. */
object YoutubeChannelParsers {
    class FeedVideo(
        val id: String,
        val title: String,
        val publishedMs: Long,
        val author: String,
        val thumbnail: String?,
        val views: Long?,
    )

    private val CHANNEL_ID = Regex("UC[0-9A-Za-z_-]{22}")

    fun isChannelId(id: String) = id.length == 24 && CHANNEL_ID.matches(id)

    /** 페이지 안의 데이터는 `\x22`처럼 이스케이프돼 있다. 이름이 나열만 된 앞쪽 글은 주소가 없어 건너뛴다. */
    private val BANNER = Regex(
        """imageBannerViewModel[^h]{0,120}(https:\\?/\\?/yt3\.googleusercontent\.com(?:[^"\\]|(?!\\x22)\\x[0-9a-fA-F]{2}|\\/)*)""",
    )
    private val HEX_ESCAPE = Regex("""\\x([0-9a-fA-F]{2})""")

    /** `imageBannerViewModel`의 첫 배너 이미지 주소 (없으면 null). */
    fun bannerUrl(html: String): String? {
        val m = BANNER.find(html) ?: return null
        return HEX_ESCAPE.replace(m.groupValues[1]) { it.groupValues[1].toInt(16).toChar().toString() }
            .replace("\\/", "/")
    }

    /** 채널 이미지: 페이지의 `og:image` (없으면 null). */
    fun logoUrl(html: String): String? {
        val m = Regex("""<meta property="og:image" content="([^"]+)"""").find(html) ?: return null
        return m.groupValues[1].takeIf { it.isNotEmpty() }
    }

    private val DESCRIPTION = Regex(
        """"channelMetadataRenderer":\{"title":"(?:[^"\\]|\\.)*","description":"((?:[^"\\]|\\.)*)"""",
    )

    /** `channelMetadataRenderer`의 채널 소개 전체 (없거나 비었으면 null). JSON 글자의 이스케이프를 풀어 준다. */
    fun description(html: String): String? {
        val m = DESCRIPTION.find(html) ?: return null
        val text = unescapeJson(m.groupValues[1]).trim()
        return text.ifEmpty { null }
    }

    private val SUBSCRIBERS = Regex("""([\d.,]+)\s*([KMB]?)\s+subscribers""")

    /** "1.91M subscribers" 같은 글에서 구독자 수 (없으면 null). */
    fun subscriberCount(html: String): Long? {
        val m = SUBSCRIBERS.find(html) ?: return null
        val n = m.groupValues[1].replace(",", "").toDoubleOrNull() ?: return null
        val unit = when (m.groupValues[2]) {
            "K" -> 1e3
            "M" -> 1e6
            "B" -> 1e9
            else -> 1.0
        }
        return Math.round(n * unit)
    }

    /** 채널 페이지 글에서 채널 id를 찾는다. 못 찾으면 null. */
    fun channelIdFromPage(html: String): String? {
        for (pattern in listOf(
            Regex(""""externalId":"(UC[0-9A-Za-z_-]{22})""""),
            Regex(""""channelId":"(UC[0-9A-Za-z_-]{22})""""),
            Regex("""youtube\.com/channel/(UC[0-9A-Za-z_-]{22})"""),
            Regex("""channel_id=(UC[0-9A-Za-z_-]{22})"""),
        )) {
            pattern.find(html)?.let { return it.groupValues[1] }
        }
        return null
    }

    private val ENTRY = Regex("""<entry>([\s\S]*?)</entry>""")
    private val THUMBNAIL = Regex("""<media:thumbnail[^>]*\burl="([^"]+)"""")
    private val VIEWS = Regex("""<media:statistics[^>]*\bviews="(\d+)"""")
    private val AUTHOR = Regex("""<author>([\s\S]*?)</author>""")

    /** 채널 RSS(Atom)를 영상 목록으로. 읽을 수 없는 항목은 건너뛴다. */
    fun feed(xml: String): List<FeedVideo> = ENTRY.findAll(xml).mapNotNull { m ->
        val body = m.groupValues[1]
        val id = tag(body, "yt:videoId") ?: return@mapNotNull null
        val title = tag(body, "title") ?: return@mapNotNull null
        val published = tag(body, "published")?.let {
            runCatching { OffsetDateTime.parse(it).toInstant().toEpochMilli() }.getOrNull()
        } ?: return@mapNotNull null
        FeedVideo(
            id = id,
            title = title,
            publishedMs = published,
            author = AUTHOR.find(body)?.let { tag(it.groupValues[1], "name") } ?: "",
            thumbnail = THUMBNAIL.find(body)?.groupValues?.get(1),
            views = VIEWS.find(body)?.groupValues?.get(1)?.toLongOrNull(),
        )
    }.toList()

    private fun tag(text: String, name: String): String? {
        val m = Regex("<$name>([\\s\\S]*?)</$name>").find(text) ?: return null
        return unescapeXml(m.groupValues[1].trim())
    }

    private fun unescapeXml(s: String): String = s
        .replace(Regex("&#(\\d+);")) { it.groupValues[1].toInt().toChar().toString() }
        .replace(Regex("&#x([0-9a-fA-F]+);")) { it.groupValues[1].toInt(16).toChar().toString() }
        .replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", "\"").replace("&apos;", "'")
        .replace("&amp;", "&")

    /** JSON 문자열 안의 이스케이프(`\n` · `\"` · `\uXXXX` …)를 푼다. */
    fun unescapeJson(s: String): String {
        val out = StringBuilder(s.length)
        var i = 0
        while (i < s.length) {
            val c = s[i]
            if (c != '\\' || i + 1 >= s.length) {
                out.append(c); i++; continue
            }
            when (val n = s[i + 1]) {
                'n' -> out.append('\n')
                'r' -> out.append('\r')
                't' -> out.append('\t')
                'b' -> out.append('\b')
                'f' -> out.append('\u000C')
                'u' -> {
                    val hex = if (i + 6 <= s.length) s.substring(i + 2, i + 6) else ""
                    val code = hex.toIntOrNull(16)
                    if (code != null) {
                        out.append(code.toChar()); i += 6; continue
                    }
                    out.append('u')
                }
                else -> out.append(n) // \" \\ \/
            }
            i += 2
        }
        return out.toString()
    }
}
