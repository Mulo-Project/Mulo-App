package com.mulo.app

import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.SocketTimeoutException
import java.net.URL
import java.net.URLEncoder

/**
 * YouTube Data API v3 읽기(내 재생목록 · 구독 채널 · 채널의 재생목록)를 네이티브에서 한다.
 * 로그인(액세스 토큰 얻기)은 Dart의 로그인 플러그인이 하고, 이 객체는 받은 토큰으로 쪽을 끝까지 읽어 앱 모델 모양으로 돌려준다.
 *
 * 실패는 [NativeChannel.CodedException]의 코드로 알린다: `unauthorized` · `no_channel` · `network` · `timeout` · `failed`.
 */
object GoogleApi {
    private const val TAG = MuloLog.NATIVE
    private const val HOST = "https://www.googleapis.com"
    private val API_DISABLED = Regex("accessNotConfigured|SERVICE_DISABLED|has not been used|quota", RegexOption.IGNORE_CASE)

    /** [kind]: `playlists`(항목: id · title · url · channel · thumbnail? · trackCount?) 또는 `subscriptions`(id · name · description · thumbnail?). */
    fun list(
        token: String,
        kind: String,
        query: Map<String, String>,
        maxPages: Int,
        onProgress: (Int) -> Unit,
    ): List<Map<String, Any?>> {
        val path = if (kind == "subscriptions") "/youtube/v3/subscriptions" else "/youtube/v3/playlists"
        val start = System.currentTimeMillis()
        val out = ArrayList<Map<String, Any?>>()
        var pageToken: String? = null
        for (i in 0 until maxPages) {
            val json = getJson(token, path, query, pageToken)
            val items = json.optJSONArray("items")
            if (items != null) {
                for (j in 0 until items.length()) {
                    val item = items.optJSONObject(j) ?: continue
                    val parsed = if (kind == "subscriptions") parseSubscription(item) else parsePlaylist(item)
                    if (parsed != null) out += parsed
                }
            }
            onProgress(out.size)
            val next = json.optString("nextPageToken").takeIf { it.isNotEmpty() }
            if (next == null || next == pageToken) break
            pageToken = next
        }
        MuloLog.d(TAG, "구글 API $kind ${out.size}개 ${System.currentTimeMillis() - start}ms")
        return out
    }

    private fun getJson(token: String, path: String, query: Map<String, String>, pageToken: String?): JSONObject {
        val params = LinkedHashMap(query)
        params["maxResults"] = "50"
        if (pageToken != null) params["pageToken"] = pageToken
        val qs = params.entries.joinToString("&") { "${enc(it.key)}=${enc(it.value)}" }
        val conn = URL("$HOST$path?$qs").openConnection() as HttpURLConnection
        var ok = false
        try {
            conn.connectTimeout = 10_000
            conn.readTimeout = 30_000
            conn.setRequestProperty("Accept", "application/json")
            conn.setRequestProperty("Authorization", "Bearer $token")
            val code = try {
                conn.responseCode
            } catch (e: SocketTimeoutException) {
                throw NativeChannel.CodedException("timeout", "timeout")
            } catch (e: IOException) {
                throw NativeChannel.CodedException("network", e.message ?: "network")
            }
            val body = try {
                (if (code in 200..299) conn.inputStream else conn.errorStream)?.bufferedReader()?.use { it.readText() } ?: ""
            } catch (e: SocketTimeoutException) {
                throw NativeChannel.CodedException("timeout", "timeout")
            } catch (e: IOException) {
                throw NativeChannel.CodedException("network", e.message ?: "network")
            }
            ok = true
            // 유튜브 채널이 없는 구글 계정은 `mine=true`에 404(channelNotFound)가 온다.
            if (code == 404) throw NativeChannel.CodedException("no_channel", errorDetail(body))
            if (code !in 200..299) {
                val detail = "$code ${errorDetail(body)}".trim()
                // API를 켜지 않았거나 할당량 문제인 403은 로그인이 풀린 것이 아니다.
                val notAuth = code == 401 || (code == 403 && !API_DISABLED.containsMatchIn(body))
                throw NativeChannel.CodedException(if (notAuth) "unauthorized" else "failed", detail)
            }
            return try {
                JSONObject(body)
            } catch (e: Exception) {
                throw NativeChannel.CodedException("failed", "bad response")
            }
        } finally {
            if (!ok) conn.disconnect()
        }
    }

    /** 구글 API 오류 본문에서 사람이 읽을 한 줄 (없으면 빈 문자열). */
    fun errorDetail(body: String): String = try {
        val error = JSONObject(body).optJSONObject("error")
        if (error == null) "" else {
            val first = error.optJSONArray("errors")?.optJSONObject(0)
            val reason = first?.optString("reason")?.takeIf { it.isNotEmpty() } ?: error.optString("status")
            "$reason ${error.optString("message")}".trim()
        }
    } catch (e: Exception) {
        ""
    }

    /** `playlists` 항목 하나 (id가 없으면 null). */
    fun parsePlaylist(item: JSONObject): Map<String, Any?>? {
        val id = item.optString("id").takeIf { it.isNotEmpty() } ?: return null
        val s = item.optJSONObject("snippet") ?: JSONObject()
        val count = item.optJSONObject("contentDetails")?.let { if (it.has("itemCount")) it.optInt("itemCount") else null }
        return mapOf(
            "id" to id,
            "title" to s.optString("title"),
            "url" to "https://www.youtube.com/playlist?list=$id",
            "channel" to s.optString("channelTitle"),
            "thumbnail" to thumbnail(s, listOf("medium", "high", "default", "standard")),
            "trackCount" to count,
        )
    }

    /** `subscriptions` 항목 하나 (채널 id가 없으면 null). */
    fun parseSubscription(item: JSONObject): Map<String, Any?>? {
        val s = item.optJSONObject("snippet") ?: JSONObject()
        val id = s.optJSONObject("resourceId")?.optString("channelId")?.takeIf { it.isNotEmpty() } ?: return null
        return mapOf(
            "id" to id,
            "name" to s.optString("title"),
            "description" to s.optString("description"),
            "thumbnail" to thumbnail(s, listOf("medium", "default", "high")),
        )
    }

    private fun thumbnail(snippet: JSONObject, order: List<String>): String? {
        val thumbs = snippet.optJSONObject("thumbnails") ?: return null
        for (key in order) {
            thumbs.optJSONObject(key)?.optString("url")?.takeIf { it.isNotEmpty() }?.let { return it }
        }
        return null
    }

    private fun enc(s: String) = URLEncoder.encode(s, "UTF-8")
}
