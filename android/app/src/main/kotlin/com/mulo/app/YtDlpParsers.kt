package com.mulo.app

import org.json.JSONArray
import org.json.JSONObject

/**
 * yt-dlp가 내놓는 JSON · 자막(VTT)을 앱이 쓰는 값으로 바꾸는 순수 함수들 (실행은 [YtDlpEngine]).
 * Dart는 여기서 나온 값을 그대로 모델에 담기만 한다.
 */
object YtDlpParsers {
    /** JSON의 문자열 칸 (없거나 비어 있으면 null). `optString`은 null 칸을 "null" 글자로 주므로 쓰지 않는다. */
    fun text(o: JSONObject, key: String): String? = (o.opt(key) as? String)?.trim()?.takeIf { it.isNotEmpty() }

    /** JSON의 숫자 칸 (정수 · 실수 모두 정수로, 아니면 null). */
    fun count(o: JSONObject, key: String): Long? = (o.opt(key) as? Number)?.let { Math.round(it.toDouble()) }

    fun strings(raw: Any?): List<String> {
        if (raw !is JSONArray) return emptyList()
        val out = ArrayList<String>()
        for (i in 0 until raw.length()) {
            val s = (raw.opt(i) as? String)?.trim()
            if (!s.isNullOrEmpty()) out.add(s)
        }
        return out
    }

    /** `20240131` → `2024-01-31`, 이미 ISO면 그대로 (아니면 null). */
    fun date(o: JSONObject, key: String): String? {
        val s = (o.opt(key) as? String)?.trim() ?: return null
        if (s.isEmpty()) return null
        return if (Regex("^\\d{8}$").matches(s)) "${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6)}" else s
    }

    /** `thumbnail`, 없으면 `thumbnails`에서 폭을 아는 것 중 500 이하에서 가장 큰 것, 그것도 없으면 마지막. */
    fun thumbnailOf(j: JSONObject): String? {
        text(j, "thumbnail")?.let { return it }
        val thumbs = j.optJSONArray("thumbnails") ?: return null
        if (thumbs.length() == 0) return null
        var pick: JSONObject? = null
        for (i in 0 until thumbs.length()) {
            val t = thumbs.optJSONObject(i) ?: continue
            val w = t.opt("width") as? Number
            if (w != null && w.toDouble() <= 500) pick = t
        }
        val chosen = pick ?: thumbs.optJSONObject(thumbs.length() - 1)
        return chosen?.let { text(it, "url") }
    }

    /** 채널 `thumbnails` 중 프로필 이미지 (가로 배너는 건너뛰고, `avatar_uncropped`가 있으면 그것). */
    fun avatarUrl(j: JSONObject): String? {
        val thumbs = j.optJSONArray("thumbnails") ?: return null
        val avatars = ArrayList<JSONObject>()
        for (i in 0 until thumbs.length()) {
            val t = thumbs.optJSONObject(i) ?: continue
            if (t.opt("url") is String && (t.opt("id")?.toString() ?: "").contains("avatar")) avatars.add(t)
        }
        if (avatars.isEmpty()) return null
        val pick = avatars.firstOrNull { it.opt("id") == "avatar_uncropped" } ?: avatars.last()
        return pick.opt("url") as String
    }

    /** `subtitles` · `automatic_captions`의 언어 코드들 (라이브 채팅 제외). */
    fun keys(raw: Any?): List<String> {
        if (raw !is JSONObject) return emptyList()
        return raw.keys().asSequence().filter { it != "live_chat" }.toList()
    }

    /**
     * `automatic_captions`에서 영상 원어 자동 자막만 (유튜브가 번역해 둔 수십 개 언어는 뺀다).
     * 번역본은 주소에 `tlang=`가 붙고, 원어는 `xx-orig` 키로 따로 온다. `-orig`가 있으면 그것만 쓴다.
     */
    fun originalAutoKeys(raw: Any?): List<String> {
        if (raw !is JSONObject) return emptyList()
        val keys = ArrayList<String>()
        for (k in raw.keys()) {
            if (k == "live_chat") continue
            val formats = raw.opt(k)
            val translated = formats is JSONArray && formats.length() > 0 &&
                (0 until formats.length()).all { (formats.opt(it) as? JSONObject)?.opt("url")?.toString()?.contains("tlang=") == true }
            if (!translated) keys.add(k)
        }
        val orig = keys.filter { it.endsWith("-orig") }
        return if (orig.isEmpty()) keys else orig
    }

    private fun isLive(j: JSONObject): Boolean {
        val status = j.opt("live_status")
        return j.opt("is_live") == true || status == "is_live" || status == "is_upcoming"
    }

    /** 곡 하나 (검색 항목 · 곡 정보). */
    fun hit(j: JSONObject): Map<String, Any?> {
        val id = (j.opt("id") as? String) ?: ""
        val seconds = (j.opt("duration") as? Number)?.let { Math.round(it.toDouble()).toInt() }
        val subtitles = keys(j.opt("subtitles"))
        val auto = originalAutoKeys(j.opt("automatic_captions"))
        return mapOf(
            "id" to id,
            "title" to ((j.opt("title") as? String) ?: ""),
            "url" to ((j.opt("webpage_url") as? String) ?: (j.opt("url") as? String) ?: "https://www.youtube.com/watch?v=$id"),
            "uploader" to ((j.opt("uploader") as? String) ?: (j.opt("channel") as? String) ?: ""),
            "seconds" to seconds,
            "thumbnail" to thumbnailOf(j),
            "categories" to strings(j.opt("categories")),
            "channelUrl" to (text(j, "channel_url") ?: text(j, "uploader_url")),
            "views" to count(j, "view_count"),
            "uploadDate" to date(j, "upload_date"),
            "description" to (text(j, "description") ?: ""),
            "likes" to count(j, "like_count"),
            "subscribers" to count(j, "channel_follower_count"),
            "creators" to strings(j.opt("creators")),
            "subtitleLangs" to (subtitles + auto).distinct(),
            "autoSubtitleLangs" to auto.filter { it !in subtitles },
            "album" to (text(j, "album") ?: ""),
            // 검색 목록의 라이브 · 예정 방송은 길이가 없다 (유튜브 일반 영상은 길이가 있다).
            "isLive" to (isLive(j) || (seconds == null && id.length == 11)),
        )
    }

    /** 검색 결과의 재생목록 항목 (재생목록이 아니면 null). */
    fun playlistHit(j: JSONObject): Map<String, Any?>? {
        val url = text(j, "url") ?: text(j, "webpage_url")
        val id = text(j, "id") ?: url?.let { listIdOf(it) }
        if (id == null || url == null || !url.contains("list=")) return null
        return mapOf(
            "id" to id,
            "title" to ((j.opt("title") as? String) ?: ""),
            "url" to url,
            "channel" to (text(j, "uploader") ?: text(j, "channel") ?: ""),
            "thumbnail" to thumbnailOf(j),
            "trackCount" to (count(j, "playlist_count") ?: count(j, "n_entries")),
        )
    }

    private fun listIdOf(url: String): String? =
        Regex("[?&]list=([^&#]+)").find(url)?.groupValues?.get(1)

    /** 곡 정보 읽기 결과: 재생목록이면 `type=playlist`, 아니면 `type=video`. */
    fun info(j: JSONObject): Map<String, Any?> {
        if (j.opt("_type") == "playlist") {
            val entries = j.optJSONArray("entries")
            val items = ArrayList<Map<String, Any?>>()
            if (entries != null) for (i in 0 until entries.length()) entries.optJSONObject(i)?.let { items.add(hit(it)) }
            return mapOf(
                "type" to "playlist",
                "title" to ((j.opt("title") as? String) ?: ""),
                "entries" to items,
                "thumbnail" to thumbnailOf(j),
            )
        }
        return mapOf("type" to "video", "hit" to hit(j))
    }

    fun channel(j: JSONObject): Map<String, Any?> =
        mapOf("thumbnail" to avatarUrl(j), "subscriberCount" to count(j, "channel_follower_count"))

    /**
     * SoundCloud 아티스트 페이지 머리말의 `og:image`(프로필 이미지) 주소 (없으면 null).
     * 곡 썸네일은 곡 커버라서 아티스트 이미지가 아니므로 이 값을 쓴다. 작은 `-large`(100px) 대신 큰 이미지로 바꾼다.
     */
    fun soundcloudAvatarFromHtml(html: String): String? {
        val isOgImage = Regex("(property|name)\\s*=\\s*[\"']og:image[\"']", RegexOption.IGNORE_CASE)
        val content = Regex("content\\s*=\\s*[\"']([^\"']+)[\"']", RegexOption.IGNORE_CASE)
        for (m in Regex("<meta\\b[^>]*>", RegexOption.IGNORE_CASE).findAll(html)) {
            val tag = m.value
            if (!isOgImage.containsMatchIn(tag)) continue
            val c = content.find(tag)?.groupValues?.get(1) ?: continue
            if (!c.startsWith("http")) continue
            return c.replace("&amp;", "&").replaceFirst(Regex("-(large|t200x200|t300x300)\\."), "-t500x500.")
        }
        return null
    }

    fun isSoundcloud(url: String): Boolean {
        val host = try { java.net.URI(url).host?.lowercase() ?: "" } catch (_: Exception) { "" }
        return host == "soundcloud.com" || host.endsWith(".soundcloud.com")
    }

    private fun headers(j: JSONObject): Map<String, String> {
        val h = j.optJSONObject("http_headers") ?: return emptyMap()
        val out = LinkedHashMap<String, String>()
        for (k in h.keys()) (h.opt(k) as? String)?.let { out[k] = it }
        return out
    }

    /** 소리 주소 하나 (주소가 없으면 null). */
    fun audio(j: JSONObject): Map<String, Any?>? {
        val url = text(j, "url") ?: return null
        return mapOf("url" to url, "headers" to headers(j))
    }

    /** 영상 주소 하나. 소리가 같이 든 형식이면 `muxed`. */
    fun video(j: JSONObject): Map<String, Any?>? {
        val url = text(j, "url") ?: return null
        return mapOf(
            "url" to url,
            "headers" to headers(j),
            "muxed" to (j.opt("vcodec")?.toString() != "none" && j.opt("acodec")?.toString() != "none"),
        )
    }

    /** 형식 목록의 `language` · `format_note`에서 오디오 트랙을 읽는다. 하나뿐이면 빈 목록. */
    fun audioLanguages(j: JSONObject): List<Map<String, Any?>> {
        val formats = j.optJSONArray("formats") ?: return emptyList()
        val byId = LinkedHashMap<String, Map<String, Any?>>()
        for (i in 0 until formats.length()) {
            val f = formats.optJSONObject(i) ?: continue
            if (f.opt("vcodec")?.toString() != "none") continue
            val id = text(f, "language") ?: continue
            if (byId.containsKey(id)) continue
            val note = text(f, "format_note") ?: ""
            byId[id] = mapOf(
                "id" to id,
                "name" to (languageName(note) ?: id),
                "isDefault" to (note.contains("default") || note.contains("original")),
            )
        }
        return if (byId.size < 2) emptyList() else byId.values.toList()
    }

    /** `English (US) original (default), medium` → `English (US)`. */
    fun languageName(note: String): String? {
        val head = note.split(',').first()
            .replace(Regex("\\((default)\\)|original|descriptive"), "")
            .trim()
        return head.ifEmpty { null }
    }

    /** yt-dlp 오류 글에서 실패 까닭을 고른다 (Dart `EngineFailure` 이름). */
    fun failureCode(stderr: String): String = when {
        stderr.contains("Unsupported URL") -> "not_found"
        stderr.contains("Unable to download") || stderr.contains("getaddrinfo") -> "network"
        else -> "failed"
    }

    /**
     * 받을 자막 언어를 고른다. 사람이 단 자막이 우선이고, [prefer] 순서(`ko` → `ko-KR` 같은 하위 코드 포함),
     * 없으면 첫 언어. 자동 자막은 원어(`-orig`)를 우선 쓴다. 쓸 자막이 없으면 null.
     */
    fun pickSubtitleLanguage(manual: List<String>, automatic: List<String>, prefer: List<String>): Pair<String, Boolean>? {
        fun choose(keys: List<String>): String? {
            if (keys.isEmpty()) return null
            for (p in prefer) for (k in keys) if (k == p || k.startsWith("$p-")) return k
            return keys.first()
        }
        choose(manual)?.let { return it to false }
        val orig = automatic.filter { it.endsWith("-orig") }
        return choose(if (orig.isEmpty()) automatic else orig)?.let { it to true }
    }

    private val TIME = Regex("(?:(\\d+):)?(\\d{1,2}):(\\d{2})[.,](\\d{1,3})\\s*-->")

    /**
     * 자막 파일(WebVTT)을 읽는다. 자동 자막은 앞 줄을 되풀이하며 이어지므로,
     * 바로 앞 칸에 이미 나온 줄은 빼고 새로 생긴 줄만 남긴다. 태그(`<c>` · `<00:01.0>`)는 지운다.
     * 칸마다 `ms`(시작, 밀리초) · `text`.
     */
    fun parseVtt(vtt: String): List<Map<String, Any?>> {
        val cues = ArrayList<Map<String, Any?>>()
        var prev = emptyList<String>()
        for (block in vtt.replace("\r\n", "\n").split(Regex("\n\\s*\n"))) {
            val lines = block.split('\n')
            val i = lines.indexOfFirst { TIME.containsMatchIn(it) }
            if (i < 0) continue
            val m = TIME.find(lines[i])!!
            val ms = (m.groupValues[1].ifEmpty { "0" }.toLong() * 3600 +
                m.groupValues[2].toLong() * 60 + m.groupValues[3].toLong()) * 1000 +
                m.groupValues[4].padEnd(3, '0').toLong()
            val text = lines.drop(i + 1).map { clean(it) }.filter { it.isNotEmpty() }
            val fresh = text.filter { it !in prev }
            prev = text
            if (fresh.isEmpty()) continue
            cues.add(mapOf("ms" to ms, "text" to fresh.joinToString(" ")))
        }
        return cues
    }

    private fun clean(line: String): String = line
        .replace(Regex("<[^>]*>"), "")
        .replace("&nbsp;", " ")
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .trim()

    /** 미리 듣기용 오디오 형식 `-f` 값: webm/opus 먼저, 없으면 바로 받는(HTTP) 오디오, 그것도 없으면 아무 오디오. */
    fun audioSelector(language: String?): String {
        if (language != null) {
            val l = "[language=$language]"
            return "bestaudio$l[ext=webm]/bestaudio$l[protocol^=http]/bestaudio$l"
        }
        return "bestaudio[ext=webm]/bestaudio[protocol^=http]/bestaudio/best"
    }

    /**
     * 화면용 영상 `-f` 값. 360p를 넘는 화질은 유튜브가 소리 든 형식을 주지 않아서(있어도 360p)
     * 영상 전용 형식을 먼저 찾고, 그 이하는 소리가 같이 든 형식을 먼저 찾는다.
     */
    fun videoSelector(height: Int): String = if (height > 360) {
        "bv[height<=$height][vcodec^=avc1]/bv[height<=$height]/b[height<=$height]/bv[height<=480]/bv"
    } else {
        "b[height<=$height][vcodec^=avc1]/b[height<=$height]/bv[height<=$height][vcodec^=avc1]/bv[height<=$height]/bv[height<=480]/bv"
    }

    /**
     * 영상 파일 저장용 `-f` 값 (확장자별): webm은 VP9 + Opus 원본, 그 밖(mp4)은 H.264 + AAC를 먼저 찾아
     * 다시 인코딩 없이 합친다. 못 찾으면 아무 코덱, 그래도 없으면 영상 · 소리가 합쳐진 형식.
     */
    fun saveSelector(height: Int, extension: String): String = if (extension == "webm") {
        "bv*[height<=$height][ext=webm]+ba[ext=webm]/bv*[height<=$height]+ba/b[height<=$height]/b"
    } else {
        "bv*[height<=$height][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=$height]+ba/b[height<=$height]/b"
    }
}
