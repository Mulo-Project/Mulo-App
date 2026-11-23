package com.mulo.app

import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap

/**
 * 유튜브 곡 · 영상의 재생 주소를 네이티브에서 읽는다 (Dart의 youtube_explode_dart가 하던 일).
 * 웹 페이지 없이 InnerTube `player` API를 클라이언트(visionOS → android_vr → android)별로 불러,
 * 파일 가운데 구간을 실제로 요청해 보고(probe) 열리는 주소만 돌려준다. 외부 라이브러리 없이 HttpURLConnection · org.json만 쓴다.
 * 앱이 백그라운드로 가도 Dart 엔진과 상관없이 돈다.
 */
object YoutubeResolver {
    private const val PLAYER_URL = "https://www.youtube.com/youtubei/v1/player?prettyPrint=false"
    private const val TAG = MuloLog.NATIVE
    private const val SESSION_TTL_MS = 30 * 60 * 1000L
    private const val DEFAULT_COOKIES = "PREF=hl=en&tz=UTC; SOCS=CAI; GPS=1"

    private const val VISIONOS_UA =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
    private const val ANDROID_VR_UA =
        "com.google.android.apps.youtube.vr.oculus/1.62.27 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip"
    private const val ANDROID_UA = "com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip"
    private const val WEB_UA =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36"

    private class Client(val name: String, val version: String, val userAgent: String, val client: JSONObject) {
        fun payload(videoId: String, sts: String?): JSONObject = JSONObject()
            .put("context", JSONObject().put("client", client))
            .put("videoId", videoId)
            .apply {
                if (sts != null) {
                    put(
                        "playbackContext",
                        JSONObject().put(
                            "contentPlaybackContext",
                            JSONObject().put("html5Preference", "HTML5_PREF_WANTS").put("signatureTimestamp", sts),
                        ),
                    )
                }
            }
    }

    private val visionOs = Client(
        "VISIONOS", "1.02", VISIONOS_UA,
        JSONObject()
            .put("clientName", "VISIONOS").put("clientVersion", "1.02")
            .put("deviceMake", "Apple").put("deviceModel", "RealityDevice17,1")
            .put("userAgent", VISIONOS_UA).put("osName", "visionOS").put("osVersion", "26.5.23O471")
            .put("hl", "en").put("timeZone", "UTC").put("utcOffsetMinutes", 0),
    )
    private val androidVr = Client(
        "ANDROID_VR", "1.62.27", ANDROID_VR_UA,
        JSONObject()
            .put("clientName", "ANDROID_VR").put("clientVersion", "1.62.27")
            .put("deviceModel", "Quest 3").put("osVersion", "12").put("osName", "Android")
            .put("androidSdkVersion", "32").put("userAgent", ANDROID_VR_UA)
            .put("hl", "en").put("timeZone", "UTC").put("utcOffsetMinutes", 0),
    )
    private val androidSdkless = Client(
        "ANDROID", "20.10.38", ANDROID_UA,
        JSONObject()
            .put("clientName", "ANDROID").put("clientVersion", "20.10.38")
            .put("userAgent", ANDROID_UA).put("hl", "en").put("timeZone", "UTC")
            .put("utcOffsetMinutes", 0).put("osName", "Android").put("osVersion", "11"),
    )
    /** 시청 페이지에서 얻는 방문자 정보 (쿠키 · visitorData · STS). 유튜브가 앱 요청으로 믿게 하려고 player 요청에 같이 보낸다. */
    private class Session(val cookie: String, val visitorData: String?, val sts: String?, val at: Long)

    @Volatile
    private var session: Session? = null

    private fun session(videoId: String, force: Boolean = false): Session {
        val now = System.currentTimeMillis()
        session?.let { if (!force && now - it.at < SESSION_TTL_MS) return it }
        val clock = now
        val conn = URL("https://www.youtube.com/watch?v=$videoId&bpctr=9999999999&has_verified=1&hl=en")
            .openConnection() as HttpURLConnection
        try {
            conn.connectTimeout = 6000
            conn.readTimeout = 10000
            conn.setRequestProperty("User-Agent", WEB_UA)
            conn.setRequestProperty("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
            conn.setRequestProperty("Accept-Language", "en-us,en;q=0.5")
            conn.setRequestProperty("Sec-Fetch-Mode", "navigate")
            conn.setRequestProperty("Cookie", DEFAULT_COOKIES)
            if (conn.responseCode != 200) throw IOException("시청 페이지 HTTP ${conn.responseCode}")
            val cookies = LinkedHashMap<String, String>()
            conn.headerFields["Set-Cookie"]?.forEach { c ->
                val pair = c.substringBefore(';')
                val name = pair.substringBefore('=')
                if (name.isNotEmpty() && pair.contains('=')) cookies[name] = pair.substringAfter('=')
            }
            cookies["PREF"] = "hl=en"; cookies["SOCS"] = "CAI"; cookies["GPS"] = "1"
            val html = conn.inputStream.bufferedReader().use { it.readText() }
            val visitor = Regex("\"visitorData\"\\s*:\\s*\"([^\"]+)\"").find(html)?.groupValues?.get(1)
            val sts = Regex("\"STS\"\\s*:\\s*(\\d+)").find(html)?.groupValues?.get(1)
            val made = Session(cookies.entries.joinToString("; ") { "${it.key}=${it.value}" }, visitor, sts, now)
            MuloLog.d(TAG, "방문자 정보 ${System.currentTimeMillis() - clock}ms visitorData=${visitor != null} sts=${sts != null}")
            session = made
            return made
        } finally {
            conn.disconnect()
        }
    }

    private val audioClients = listOf(visionOs, androidVr, androidSdkless)

    /** 읽은 주소를 잠깐 기억한다: 미리 듣기가 읽은 주소를 영상 화면 · 미리 읽기가 다시 읽지 않게. 끊김 복구는 [fresh]로 건너뛴다. */
    private val addressCache = ConcurrentHashMap<String, Pair<Long, Map<String, Any?>>>()
    private const val ADDRESS_TTL_MS = 10 * 60 * 1000L

    private fun cached(key: String, fresh: Boolean, load: () -> Map<String, Any?>?): Map<String, Any?>? {
        val now = System.currentTimeMillis()
        if (!fresh) {
            addressCache[key]?.let { (at, value) -> if (now - at < ADDRESS_TTL_MS) return value }
        }
        val value = load()
        if (value != null) addressCache[key] = now to value else addressCache.remove(key)
        return value
    }

    /** 소리 주소. 못 읽으면 null, 모든 클라이언트가 실패하면 까닭을 담은 예외. */
    fun audio(videoId: String, language: String?, preferWebm: Boolean, fresh: Boolean = false): Map<String, Any?>? =
        cached("a|$videoId|$language|$preferWebm", fresh) { timed("소리") { audioInner(videoId, language, preferWebm) } }

    fun video(videoId: String, maxHeight: Int, fresh: Boolean = false): Map<String, Any?>? =
        cached("v|$videoId|$maxHeight", fresh) { timed("영상") { videoInner(videoId, maxHeight) } }

    /** 걸린 시간을 debug 로그로 남긴다 (`adb logcat -s MuloNative`, `주소 읽기 소리 1234ms 읽음`). */
    private fun <T> timed(label: String, block: () -> T?): T? {
        val start = System.currentTimeMillis()
        try {
            val r = block()
            MuloLog.d(TAG, "주소 읽기 $label ${System.currentTimeMillis() - start}ms ${if (r == null) "없음" else "읽음"}")
            return r
        } catch (e: Exception) {
            MuloLog.d(TAG, "주소 읽기 $label ${System.currentTimeMillis() - start}ms 실패 ${oneLine(e.message ?: "")}")
            throw e
        }
    }

    private fun audioInner(videoId: String, language: String?, preferWebm: Boolean): Map<String, Any?>? {
        val errors = mutableListOf<String>()
        var firstReadable: List<YtFormat>? = null
        for (client in audioClients) {
            val clock = System.currentTimeMillis()
            val ordered = try {
                YoutubeFormats.orderAudio(fetchFormats(client, videoId), preferWebm, language)
            } catch (e: LiveVideoException) {
                throw e
            } catch (e: Exception) {
                MuloLog.d(TAG, "소리 ${client.name} ${System.currentTimeMillis() - clock}ms 실패 ${oneLine(e.toString())}")
                errors += oneLine(e.message ?: e.toString()); continue
            }
            MuloLog.d(TAG, "소리 ${client.name} ${System.currentTimeMillis() - clock}ms 형식 ${ordered.size}개")
            if (ordered.isEmpty()) continue
            if (firstReadable == null) firstReadable = ordered
            if (canReadMiddle(ordered.first())) return audioMap(ordered)
            MuloLog.d(TAG, "소리 ${client.name} 구간 확인 실패")
            errors += "${client.name}: 구간 403"
        }
        firstReadable?.let { return audioMap(it) }
        session = null // 방문자 정보가 낡았을 수 있으니 다음에 새로 받는다
        if (errors.isNotEmpty()) throw IOException(errors.joinToString(" | "))
        return null
    }

    /** 영상 주소. visionOS(소리 든 형식을 줄 수 있다) → android_vr(영상 전용만, 둘 다 JS 풀이 없이 쓸 수 있는 주소) 순. 못 읽으면 null. */
    private fun videoInner(videoId: String, maxHeight: Int): Map<String, Any?>? {
        for (client in listOf(visionOs, androidVr)) {
            val all = try {
                fetchFormats(client, videoId)
            } catch (e: LiveVideoException) {
                throw e
            } catch (e: Exception) {
                MuloLog.d(TAG, "영상 ${client.name} 읽기 실패 ${oneLine(e.toString())}")
                continue
            }
            val (best, muxed) = YoutubeFormats.pickVideo(all, maxHeight) ?: run {
                MuloLog.d(TAG, "영상 ${client.name} 쓸 형식 없음 (전체 ${all.size}개)")
                continue
            }
            if (!canReadMiddle(best)) {
                MuloLog.d(TAG, "영상 ${client.name} 구간 확인 실패")
                continue
            }
            return mapOf("url" to best.url, "headers" to headers(best.url), "muxed" to muxed)
        }
        session = null
        return null
    }

    /** 저장할 영상 (소리가 든 형식이면 [audio]는 null). */
    class SaveSources(val video: YtFormat, val audio: YtFormat?)

    /**
     * 영상 저장용 주소: 영상(+없으면 같은 형식의 소리)을 구간 확인까지 통과한 클라이언트에서 고른다. 못 찾으면 null.
     * [container]는 저장할 파일 형식(mp4 · webm): 같은 형식의 영상 · 소리를 골라 다시 인코딩 없이 합칠 수 있게 한다.
     * 받을 때는 [headersFor]의 헤더를 같이 보낸다.
     */
    fun saveSources(videoId: String, maxHeight: Int, container: String = "mp4"): SaveSources? = timed("저장용") {
        var found: SaveSources? = null
        for (client in listOf(visionOs, androidVr)) {
            val all = try {
                fetchFormats(client, videoId)
            } catch (e: LiveVideoException) {
                throw e
            } catch (e: Exception) {
                MuloLog.d(TAG, "저장용 ${client.name} 읽기 실패 ${oneLine(e.toString())}")
                continue
            }
            val (best, muxed) = YoutubeFormats.pickVideo(all, maxHeight, container) ?: continue
            if (!canReadMiddle(best)) continue
            if (muxed) { found = SaveSources(best, null); break }
            val audio = YoutubeFormats.orderAudio(all, container == "webm", null).firstOrNull { it.container == container } ?: continue
            if (!canReadMiddle(audio)) continue
            found = SaveSources(best, audio)
            break
        }
        if (found == null) session = null
        found
    }

    /** 이 주소를 받을 때 같이 보낼 헤더. */
    fun headersFor(url: String): Map<String, String> = headers(url)

    /** 언어 트랙이 둘 이상 든 클라이언트를 찾아 그 목록을. 없으면 빈 목록. */
    fun languages(videoId: String): List<Map<String, Any?>> {
        for (client in audioClients) {
            val found = try {
                YoutubeFormats.languages(fetchFormats(client, videoId))
            } catch (e: Exception) {
                continue
            }
            if (found.size > 1) {
                return found.map { (id, name, isDefault) -> mapOf("id" to id, "name" to name, "isDefault" to isDefault) }
            }
        }
        return emptyList()
    }

    private fun audioMap(ordered: List<YtFormat>): Map<String, Any?> = mapOf(
        "url" to ordered.first().url,
        "headers" to headers(ordered.first().url),
        "fallbacks" to ordered.drop(1).take(3).map { mapOf("url" to it.url, "headers" to headers(it.url)) },
    )

    private fun clientOf(url: String): String? = Regex("[?&]c=([^&]+)").find(url)?.groupValues?.get(1)

    /** 주소의 `c`(클라이언트) 값에 맞는 User-Agent. 이 주소를 받을 때 같이 보내야 한다. */
    private fun headers(url: String): Map<String, String> = mapOf(
        "user-agent" to when (clientOf(url)) {
            "ANDROID" -> ANDROID_UA
            "ANDROID_VR" -> ANDROID_VR_UA
            "VISIONOS" -> VISIONOS_UA
            else -> WEB_UA
        },
    )

    /** 라이브 중이거나 예정인 영상 (받을 수 없다). 다른 클라이언트나 yt-dlp로 넘어가지 않고 그대로 알린다. */
    class LiveVideoException : IOException("실시간 영상은 받을 수 없어요")

    private fun fetchFormats(client: Client, videoId: String): List<YtFormat> {
        val root = playerRoot(client, videoId)
        val details = root.optJSONObject("videoDetails")
        if (details != null && (details.optBoolean("isLive") || details.optBoolean("isUpcoming") ||
                details.optString("lengthSeconds") == "0")
        ) throw LiveVideoException()
        val data = root.optJSONObject("streamingData") ?: throw IOException("${client.name}: 스트림 없음")
        return parse(data.optJSONArray("formats"), true) + parse(data.optJSONArray("adaptiveFormats"), false)
    }

    /** InnerTube `player` 응답 (재생 가능 상태가 OK가 아니면 예외). */
    private fun playerRoot(client: Client, videoId: String): JSONObject {
        // 방문자 정보를 못 얻어도 그냥 시도한다.
        val sess = try {
            session(videoId)
        } catch (e: Exception) {
            MuloLog.d(TAG, "방문자 정보 실패 ${oneLine(e.toString())}")
            null
        }
        val conn = URL(PLAYER_URL).openConnection() as HttpURLConnection
        try {
            conn.requestMethod = "POST"
            conn.connectTimeout = 6000
            conn.readTimeout = 10000
            conn.doOutput = true
            conn.setRequestProperty("User-Agent", client.userAgent)
            conn.setRequestProperty("X-Youtube-Client-Name", client.name)
            conn.setRequestProperty("X-Youtube-Client-Version", client.version)
            conn.setRequestProperty("Origin", "https://www.youtube.com")
            conn.setRequestProperty("Sec-Fetch-Mode", "navigate")
            conn.setRequestProperty("Content-Type", "application/json")
            if (sess != null) {
                conn.setRequestProperty("Cookie", sess.cookie)
                sess.visitorData?.let { conn.setRequestProperty("X-Goog-Visitor-Id", it) }
            }
            conn.outputStream.use { it.write(client.payload(videoId, sess?.sts).toString().toByteArray()) }
            val code = conn.responseCode
            if (code != 200) throw IOException("${client.name}: HTTP $code")
            val root = JSONObject(conn.inputStream.bufferedReader().use { it.readText() })
            val status = root.optJSONObject("playabilityStatus")
            if (status != null && status.optString("status") != "OK") {
                throw IOException("${client.name}: ${status.optString("reason", status.optString("status"))}")
            }
            return root
        } finally {
            conn.disconnect()
        }
    }

    /**
     * 곡 정보(상세 화면): 제목 · 채널 · 길이 · 조회수 · 설명 · 올린 날 · 분류 · 자막 언어.
     * `player` 응답의 videoDetails · microformat · captions에서 읽는다 (yt-dlp를 띄우지 않는다).
     * 좋아요 수 · 구독자 수 · 공동 작업자 · 앨범은 이 응답에 없어 담지 않는다. 못 읽으면 예외.
     */
    fun info(videoId: String): Map<String, Any?> = timed("곡 정보") { infoInner(videoId) }!!

    private fun infoInner(videoId: String): Map<String, Any?> {
        val errors = mutableListOf<String>()
        for (client in listOf(visionOs, androidVr)) {
            val root = try {
                playerRoot(client, videoId)
            } catch (e: Exception) {
                errors += oneLine(e.message ?: e.toString()); continue
            }
            val d = root.optJSONObject("videoDetails") ?: continue
            val micro = root.optJSONObject("microformat")?.optJSONObject("playerMicroformatRenderer")
            val thumbs = d.optJSONObject("thumbnail")?.optJSONArray("thumbnails")
            val tracks = root.optJSONObject("captions")?.optJSONObject("playerCaptionsTracklistRenderer")
                ?.optJSONArray("captionTracks")
            val manual = LinkedHashSet<String>()
            val auto = LinkedHashSet<String>()
            if (tracks != null) {
                for (i in 0 until tracks.length()) {
                    val t = tracks.optJSONObject(i) ?: continue
                    val lang = t.optString("languageCode").takeIf { it.isNotEmpty() } ?: continue
                    if (t.optString("kind") == "asr") auto += lang else manual += lang
                }
            }
            val live = d.optBoolean("isLive") || d.optBoolean("isUpcoming")
            return mapOf(
                "id" to videoId,
                "title" to d.optString("title"),
                "author" to d.optString("author"),
                "channelId" to d.optString("channelId").takeIf { it.isNotEmpty() },
                "description" to d.optString("shortDescription"),
                "seconds" to d.optString("lengthSeconds").toIntOrNull(),
                "views" to d.optString("viewCount").toLongOrNull(),
                "isLive" to live,
                "thumbnail" to thumbs?.let { if (it.length() == 0) null else it.optJSONObject(it.length() - 1)?.optString("url") },
                "category" to micro?.optString("category")?.takeIf { it.isNotEmpty() },
                "uploadDate" to (micro?.optString("uploadDate")?.takeIf { it.isNotEmpty() }
                    ?: micro?.optString("publishDate")?.takeIf { it.isNotEmpty() }),
                "subtitleLangs" to (manual + auto).toList(),
                "autoSubtitleLangs" to auto.filter { it !in manual },
            )
        }
        throw IOException(errors.joinToString(" | ").ifEmpty { "곡 정보 없음" })
    }

    /**
     * 영상 자막을 yt-dlp 없이 읽는다: `player` 응답의 `captionTracks`에서 [prefer]에 맞는 언어를 골라 그 자막 주소를
     * json3로 받아 줄(`ms` · `text`)로 바꾼다. 쓸 자막이 없거나 주소가 빈 응답이면(유튜브가 인증값을 요구하는 경우)
     * null을 돌려주고, 부른 쪽이 yt-dlp로 넘어간다. 결과는 yt-dlp 경로와 같은 모양 (language · automatic · cues).
     */
    fun subtitles(videoId: String, prefer: List<String>): Map<String, Any?>? {
        val start = System.currentTimeMillis()
        var reason = "자막 없음"
        for (client in listOf(androidVr, visionOs)) {
            try {
                val root = playerRoot(client, videoId)
                val tracks = root.optJSONObject("captions")?.optJSONObject("playerCaptionsTracklistRenderer")
                    ?.optJSONArray("captionTracks") ?: continue
                val manual = ArrayList<String>()
                val auto = ArrayList<String>()
                for (i in 0 until tracks.length()) {
                    val t = tracks.optJSONObject(i) ?: continue
                    val lang = t.optString("languageCode").takeIf { it.isNotEmpty() } ?: continue
                    if (t.optString("kind") == "asr") auto += lang else manual += lang
                }
                val (language, automatic) = YtDlpParsers.pickSubtitleLanguage(manual, auto, prefer) ?: continue
                var baseUrl: String? = null
                for (i in 0 until tracks.length()) {
                    val t = tracks.optJSONObject(i) ?: continue
                    if (t.optString("languageCode") == language && (t.optString("kind") == "asr") == automatic) {
                        baseUrl = t.optString("baseUrl").takeIf { it.isNotEmpty() }
                        break
                    }
                }
                if (baseUrl == null) continue
                val cues = fetchCaptionCues(client, baseUrl)
                if (cues.isEmpty()) {
                    reason = "${client.name}: 빈 자막 응답"
                    continue
                }
                MuloLog.d(TAG, "주소 읽기 자막 ${System.currentTimeMillis() - start}ms 읽음 ${client.name} ${cues.size}줄")
                return mapOf("language" to language, "automatic" to automatic, "cues" to cues)
            } catch (e: Exception) {
                reason = oneLine(e.message ?: e.toString())
            }
        }
        MuloLog.d(TAG, "주소 읽기 자막 ${System.currentTimeMillis() - start}ms 없음 ($reason): yt-dlp로 넘어감")
        return null
    }

    /** 자막 주소를 json3로 받아 줄로 바꾼다. 빈 응답 · 형식이 다르면 빈 목록. */
    private fun fetchCaptionCues(client: Client, baseUrl: String): List<Map<String, Any?>> {
        val url = if (baseUrl.contains("fmt=")) baseUrl.replace(Regex("fmt=[^&]*"), "fmt=json3") else "$baseUrl&fmt=json3"
        val sess = session
        val conn = URL(url).openConnection() as HttpURLConnection
        try {
            conn.connectTimeout = 5000
            conn.readTimeout = 8000
            conn.setRequestProperty("User-Agent", client.userAgent)
            if (sess != null) conn.setRequestProperty("Cookie", sess.cookie)
            if (conn.responseCode != 200) throw IOException("자막 HTTP ${conn.responseCode}")
            val body = conn.inputStream.bufferedReader().use { it.readText() }
            if (body.isBlank()) return emptyList()
            val events = JSONObject(body).optJSONArray("events") ?: return emptyList()
            val cues = ArrayList<Map<String, Any?>>()
            for (i in 0 until events.length()) {
                val e = events.optJSONObject(i) ?: continue
                val segs = e.optJSONArray("segs") ?: continue
                val text = StringBuilder()
                for (j in 0 until segs.length()) text.append(segs.optJSONObject(j)?.optString("utf8") ?: "")
                val line = text.toString().replace('\n', ' ').trim()
                if (line.isEmpty()) continue
                cues += mapOf("ms" to e.optLong("tStartMs"), "text" to line)
            }
            return cues
        } finally {
            conn.disconnect()
        }
    }

    private fun parse(array: JSONArray?, muxed: Boolean): List<YtFormat> {
        if (array == null) return emptyList()
        val out = mutableListOf<YtFormat>()
        for (i in 0 until array.length()) {
            val o = array.optJSONObject(i) ?: continue
            val url = o.optString("url")
            if (url.isEmpty()) continue // signatureCipher 주소는 JS 풀이가 필요해 쓰지 않는다
            val length = o.optString("contentLength").toLongOrNull()
                ?: Regex("[?&]clen=(\\d+)").find(url)?.groupValues?.get(1)?.toLongOrNull()
                ?: 0L
            val track = o.optJSONObject("audioTrack")
            out += YtFormat(
                itag = o.optInt("itag"),
                url = url,
                mime = o.optString("mimeType"),
                bitrate = o.optLong("bitrate"),
                height = o.optInt("height"),
                contentLength = length,
                muxed = muxed,
                trackId = track?.optString("id")?.takeIf { it.isNotEmpty() },
                trackName = track?.optString("displayName")?.takeIf { it.isNotEmpty() },
                trackDefault = track?.optBoolean("audioIsDefault") ?: false,
            )
        }
        return out
    }

    /** 파일 가운데 1KB를 실제로 요청해 열리는지 본다 (PO 토큰 없는 주소는 앞 일부만 주고 403이라 걸러낸다). 확인 자체가 안 되면 쓴다. */
    private fun canReadMiddle(f: YtFormat): Boolean {
        val conn = try {
            URL(f.url).openConnection() as HttpURLConnection
        } catch (e: Exception) {
            return true
        }
        return try {
            // 확인이 막혀도 오래 붙들지 않는다 (시간 초과는 "확인 못 함"으로 쓴다).
            conn.connectTimeout = 2500
            conn.readTimeout = 2500
            headers(f.url).forEach { (k, v) -> conn.setRequestProperty(k, v) }
            // 길이를 모르는 형식은 처음 1KB로 확인한다.
            val from = if (f.contentLength > 4096) f.contentLength / 2 else 0
            conn.setRequestProperty("Range", "bytes=$from-${from + 1023}")
            val clock = System.currentTimeMillis()
            val code = conn.responseCode
            MuloLog.d(TAG, "구간 확인 ${clientOf(f.url)} $code ${System.currentTimeMillis() - clock}ms")
            code == 206 || code == 200
        } catch (e: Exception) {
            MuloLog.d(TAG, "구간 확인 ${clientOf(f.url)} 응답 없음 ${oneLine(e.toString())}")
            true
        } finally {
            conn.disconnect()
        }
    }

    private fun oneLine(s: String) = s.lines().map { it.trim() }.filter { it.isNotEmpty() }.joinToString(" / ")
}
