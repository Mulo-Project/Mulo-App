package com.mulo.app

import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * 유튜브 키워드 검색 · 재생목록 곡 목록을 네이티브에서 읽는다 (yt-dlp를 한 번 띄우는 것보다 훨씬 빠르다).
 * InnerTube `search` · `browse` API(WEB 클라이언트)를 HttpURLConnection · org.json만으로 부른다.
 *
 * - 검색: 같은 검색어의 다음 쪽은 앞에서 받은 결과 뒤에서 이어 읽는다(continuation). 최근 검색 몇 개만 기억한다.
 * - 재생목록: continuation을 끝까지 따라가 모든 곡을 돌려준다 (한 번에 100곡씩).
 * 응답 모양이 바뀌어 못 읽으면 빈 결과가 아니라 예외를 던져, Dart가 yt-dlp로 넘어가게 한다.
 */
object YoutubeBrowser {
    private const val TAG = MuloLog.NATIVE
    private const val API = "https://www.youtube.com/youtubei/v1"
    private const val VIDEO_FILTER = "EgIQAQ==" // 검색 필터: 동영상만
    private const val MAX_SESSIONS = 3
    private const val MAX_PLAYLIST_PAGES = 60 // 6000곡까지

    private val WEB_CLIENT: JSONObject
        get() = JSONObject()
            .put("clientName", "WEB").put("clientVersion", "2.20250925.01.00")
            .put("hl", "en").put("timeZone", "UTC").put("utcOffsetMinutes", 0)

    private const val WEB_UA =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    /** 곡 하나 (Dart의 MediaHit에 대응). 모르는 값은 null. */
    class Item(
        val id: String,
        val title: String,
        val uploader: String,
        val seconds: Int?,
        val thumbnail: String?,
        val channelId: String?,
        val views: Long?,
        val isLive: Boolean,
        val description: String,
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "id" to id, "title" to title, "uploader" to uploader, "seconds" to seconds,
            "thumbnail" to thumbnail, "channelId" to channelId, "views" to views,
            "isLive" to isLive, "description" to description,
        )
    }

    private class SearchSession(val query: String) {
        val all = ArrayList<Item>()
        val seen = HashSet<String>()
        var token: String? = null
        var started = false
        var done = false
    }

    private val sessions = object : LinkedHashMap<String, SearchSession>(8, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, SearchSession>?) = size > MAX_SESSIONS
    }

    /** [page]쪽(0부터) [size]개. 반환: items · hasNext. */
    fun search(query: String, page: Int, size: Int): Map<String, Any?> {
        val start = System.currentTimeMillis()
        val session = synchronized(sessions) { sessions.getOrPut(query) { SearchSession(query) } }
        // 같은 검색의 요청이 겹쳐도 차례로 읽는다 (같은 continuation을 두 번 쓰지 않게).
        synchronized(session) {
            val want = (page + 1) * size
            var requests = 0
            try {
                while (session.all.size < want && !session.done) {
                    val body = JSONObject().put("context", JSONObject().put("client", WEB_CLIENT))
                    if (!session.started) body.put("query", query).put("params", VIDEO_FILTER)
                    else body.put("continuation", session.token)
                    val root = post("search", body)
                    requests++
                    session.started = true
                    var token: String? = null
                    for (section in searchSections(root)) {
                        section.optJSONObject("itemSectionRenderer")?.optJSONArray("contents")?.let { contents ->
                            for (i in 0 until contents.length()) {
                                val item = parseVideo(contents.optJSONObject(i)?.optJSONObject("videoRenderer")) ?: continue
                                if (session.seen.add(item.id)) session.all += item
                            }
                        }
                        continuationToken(section)?.let { token = it }
                    }
                    session.token = token
                    if (token == null) session.done = true
                }
            } catch (e: Exception) {
                // 앞에서 읽은 결과가 있어도 이 쪽을 못 채웠으면 알린다 (일부만 주면 다음 쪽 순서가 어긋난다).
                synchronized(sessions) { sessions.remove(query) }
                MuloLog.d(TAG, "검색 ${System.currentTimeMillis() - start}ms 실패 ${oneLine(e.toString())}")
                throw e
            }
            val from = page * size
            val end = minOf(session.all.size, want)
            val items = if (from >= end) emptyList() else session.all.subList(from, end).map { it.toMap() }
            if (items.isEmpty() && page == 0) throw IOException("검색 결과를 읽지 못했다")
            MuloLog.d(TAG, "검색 쪽$page ${items.size}개 요청 ${requests}번 ${System.currentTimeMillis() - start}ms")
            return mapOf("items" to items, "hasNext" to (session.all.size > end || !session.done))
        }
    }

    /** 재생목록의 모든 곡. 반환: title · items. */
    fun playlist(playlistId: String): Map<String, Any?> {
        val start = System.currentTimeMillis()
        val items = ArrayList<Item>()
        val seen = HashSet<String>()
        var title = ""
        var token: String? = null
        var pages = 0
        try {
            do {
                val body = JSONObject().put("context", JSONObject().put("client", WEB_CLIENT))
                if (token == null) body.put("browseId", "VL$playlistId") else body.put("continuation", token)
                val root = post("browse", body)
                pages++
                if (pages == 1) {
                    title = root.optJSONObject("metadata")?.optJSONObject("playlistMetadataRenderer")?.optString("title")
                        ?: root.optJSONObject("header")?.optJSONObject("playlistHeaderRenderer")
                            ?.optJSONObject("title")?.optString("simpleText")
                        ?: ""
                }
                token = null
                val list = playlistItems(root)
                for (i in 0 until list.length()) {
                    val o = list.optJSONObject(i) ?: continue
                    val item = parsePlaylistVideo(o.optJSONObject("playlistVideoRenderer"))
                    if (item != null) {
                        if (seen.add(item.id)) items += item
                    } else {
                        continuationToken(o)?.let { token = it }
                    }
                }
            } while (token != null && pages < MAX_PLAYLIST_PAGES)
        } catch (e: Exception) {
            MuloLog.d(TAG, "재생목록 ${System.currentTimeMillis() - start}ms 실패 ${oneLine(e.toString())}")
            throw e
        }
        if (items.isEmpty()) throw IOException("재생목록 곡을 읽지 못했다")
        MuloLog.d(TAG, "재생목록 ${items.size}곡 요청 ${pages}번 ${System.currentTimeMillis() - start}ms")
        return mapOf("title" to title, "items" to items.map { it.toMap() })
    }

    // ---- 응답 읽기 ----

    /** 검색 응답에서 섹션 목록: 처음 쪽은 contents, 이어 받은 쪽은 continuationItems. */
    private fun searchSections(root: JSONObject): List<JSONObject> {
        val array: JSONArray? = root.optJSONObject("contents")
            ?.optJSONObject("twoColumnSearchResultsRenderer")?.optJSONObject("primaryContents")
            ?.optJSONObject("sectionListRenderer")?.optJSONArray("contents")
            ?: root.optJSONArray("onResponseReceivedCommands")?.optJSONObject(0)
                ?.optJSONObject("appendContinuationItemsAction")?.optJSONArray("continuationItems")
        return array.toObjects()
    }

    /** 재생목록 응답에서 곡 · continuation 항목 목록. */
    private fun playlistItems(root: JSONObject): JSONArray {
        val actions = root.optJSONArray("onResponseReceivedActions") ?: root.optJSONArray("onResponseReceivedCommands")
        if (actions != null) {
            for (i in 0 until actions.length()) {
                val a = actions.optJSONObject(i) ?: continue
                (a.optJSONObject("appendContinuationItemsAction") ?: a.optJSONObject("reloadContinuationItemsCommand"))
                    ?.optJSONArray("continuationItems")?.let { return it }
            }
        }
        val tabs = root.optJSONObject("contents")?.optJSONObject("twoColumnBrowseResultsRenderer")
            ?.optJSONArray("tabs") ?: return JSONArray()
        for (t in tabs.toObjects()) {
            val sections = t.optJSONObject("tabRenderer")?.optJSONObject("content")
                ?.optJSONObject("sectionListRenderer")?.optJSONArray("contents") ?: continue
            for (s in sections.toObjects()) {
                val contents = s.optJSONObject("itemSectionRenderer")?.optJSONArray("contents") ?: continue
                for (c in contents.toObjects()) {
                    c.optJSONObject("playlistVideoListRenderer")?.optJSONArray("contents")?.let { return it }
                }
            }
        }
        return JSONArray()
    }

    private fun continuationToken(o: JSONObject): String? {
        val endpoint = o.optJSONObject("continuationItemRenderer")?.optJSONObject("continuationEndpoint") ?: return null
        endpoint.optJSONObject("continuationCommand")?.optString("token")?.takeIf { it.isNotEmpty() }?.let { return it }
        val cmds = endpoint.optJSONObject("commandExecutorCommand")?.optJSONArray("commands") ?: return null
        for (c in cmds.toObjects()) {
            c.optJSONObject("continuationCommand")?.optString("token")?.takeIf { it.isNotEmpty() }?.let { return it }
        }
        return null
    }

    private fun parseVideo(r: JSONObject?): Item? {
        if (r == null) return null
        val id = r.optString("videoId").takeIf { it.isNotEmpty() } ?: return null
        val length = r.optJSONObject("lengthText")?.optString("simpleText")?.takeIf { it.isNotEmpty() }
        val seconds = length?.let { clock(it) }
        val viewRuns = r.optJSONObject("viewCountText")?.optJSONArray("runs")
        val watching = viewRuns != null && viewRuns.length() > 1 &&
            viewRuns.optJSONObject(1)?.optString("text")?.trim() == "watching"
        val viewText = r.optJSONObject("viewCountText")?.optString("simpleText")?.takeIf { it.isNotEmpty() }
            ?: viewRuns?.optJSONObject(0)?.optString("text")
        val owner = r.optJSONObject("ownerText")?.optJSONArray("runs")
        return Item(
            id = id,
            title = runs(r.optJSONObject("title")),
            uploader = runs(r.optJSONObject("ownerText")),
            seconds = seconds,
            thumbnail = lastThumbnail(r.optJSONObject("thumbnail")) ?: "https://i.ytimg.com/vi/$id/hqdefault.jpg",
            channelId = owner?.optJSONObject(0)?.optJSONObject("navigationEndpoint")
                ?.optJSONObject("browseEndpoint")?.optString("browseId")?.takeIf { it.isNotEmpty() },
            views = if (watching) null else viewText?.filter { it.isDigit() }?.toLongOrNull(),
            // 길이가 없으면 진행 중이거나 예정인 방송이다.
            isLive = watching || seconds == null,
            description = runs(r.optJSONArray("detailedMetadataSnippets")?.optJSONObject(0)?.optJSONObject("snippetText")),
        )
    }

    private fun parsePlaylistVideo(r: JSONObject?): Item? {
        if (r == null) return null
        val id = r.optString("videoId").takeIf { it.isNotEmpty() } ?: return null
        val title = runs(r.optJSONObject("title"))
        // 비공개 · 삭제된 곡은 이름이 자리표시자로 온다.
        if (title.isEmpty() || title == "[Private video]" || title == "[Deleted video]" ||
            r.has("isPlayable") && !r.optBoolean("isPlayable", true)
        ) return null
        val seconds = r.optString("lengthSeconds").toIntOrNull()
        val byline = r.optJSONObject("shortBylineText") ?: r.optJSONObject("ownerText")
        return Item(
            id = id,
            title = title,
            uploader = runs(byline),
            seconds = seconds,
            thumbnail = lastThumbnail(r.optJSONObject("thumbnail")) ?: "https://i.ytimg.com/vi/$id/hqdefault.jpg",
            channelId = byline?.optJSONArray("runs")?.optJSONObject(0)?.optJSONObject("navigationEndpoint")
                ?.optJSONObject("browseEndpoint")?.optString("browseId")?.takeIf { it.isNotEmpty() },
            views = null,
            isLive = seconds == null || seconds == 0,
            description = "",
        )
    }

    private fun runs(o: JSONObject?): String {
        if (o == null) return ""
        o.optString("simpleText").takeIf { it.isNotEmpty() }?.let { return it }
        return runs(o.optJSONArray("runs"))
    }

    private fun runs(a: JSONArray?): String {
        if (a == null) return ""
        val sb = StringBuilder()
        for (i in 0 until a.length()) sb.append(a.optJSONObject(i)?.optString("text") ?: "")
        return sb.toString()
    }

    private fun lastThumbnail(o: JSONObject?): String? {
        val a = o?.optJSONArray("thumbnails") ?: return null
        if (a.length() == 0) return null
        return a.optJSONObject(a.length() - 1)?.optString("url")?.takeIf { it.isNotEmpty() }
    }

    /** `3:45` · `1:02:03` → 초. 읽을 수 없으면 null. */
    private fun clock(text: String): Int? {
        val parts = text.trim().split(':')
        if (parts.isEmpty() || parts.size > 3) return null
        var seconds = 0
        for (p in parts) seconds = seconds * 60 + (p.toIntOrNull() ?: return null)
        return seconds
    }

    private fun JSONArray?.toObjects(): List<JSONObject> {
        if (this == null) return emptyList()
        val out = ArrayList<JSONObject>(length())
        for (i in 0 until length()) optJSONObject(i)?.let { out += it }
        return out
    }

    private fun post(action: String, body: JSONObject): JSONObject {
        val conn = URL("$API/$action?prettyPrint=false").openConnection() as HttpURLConnection
        try {
            conn.requestMethod = "POST"
            conn.connectTimeout = 6000
            conn.readTimeout = 10000
            conn.doOutput = true
            conn.setRequestProperty("User-Agent", WEB_UA)
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Accept-Language", "en-US,en;q=0.9")
            conn.setRequestProperty("Origin", "https://www.youtube.com")
            conn.setRequestProperty("Cookie", "PREF=hl=en&tz=UTC; SOCS=CAI")
            conn.outputStream.use { it.write(body.toString().toByteArray()) }
            val code = conn.responseCode
            if (code != 200) throw IOException("$action: HTTP $code")
            return JSONObject(conn.inputStream.bufferedReader().use { it.readText() })
        } finally {
            conn.disconnect()
        }
    }

    private fun oneLine(s: String) = s.lines().map { it.trim() }.filter { it.isNotEmpty() }.joinToString(" / ")
}
