package com.mulo.app

import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

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

    /** 소리 주소. 못 읽으면 null, 모든 클라이언트가 실패하면 까닭을 담은 예외. */
    fun audio(videoId: String, language: String?, preferWebm: Boolean): Map<String, Any?>? =
        timed("소리") { audioInner(videoId, language, preferWebm) }

    fun video(videoId: String, maxHeight: Int): Map<String, Any?>? = timed("영상") { videoInner(videoId, maxHeight) }

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

    private fun fetchFormats(client: Client, videoId: String): List<YtFormat> {
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
            val data = root.optJSONObject("streamingData") ?: throw IOException("${client.name}: 스트림 없음")
            return parse(data.optJSONArray("formats"), true) + parse(data.optJSONArray("adaptiveFormats"), false)
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
