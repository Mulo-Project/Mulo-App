package com.mulo.app

/** 유튜브 player 응답의 형식 하나 (주소를 바로 쓸 수 있는 것만 담는다). */
data class YtFormat(
    val itag: Int,
    val url: String,
    val mime: String,
    val bitrate: Long,
    val height: Int,
    val contentLength: Long,
    /** `formats`(소리 든 형식)에서 왔는지. adaptive 영상 형식은 false. */
    val muxed: Boolean,
    val trackId: String? = null,
    val trackName: String? = null,
    val trackDefault: Boolean = false,
) {
    val type: String get() = mime.substringBefore('/')
    val container: String get() = mime.substringAfter('/').substringBefore(';').trim()
    val isAudioOnly: Boolean get() = type == "audio"
    val isVideo: Boolean get() = type == "video"
}

/** 형식 고르기 규칙. 순수 함수라 단위 테스트한다 (explode_engine.dart에서 옮긴 규칙). */
object YoutubeFormats {
    /** 오디오 언어 id: 트랙 id `en-US.4` → `en-US`. */
    fun languageId(trackId: String): String {
        val dot = trackId.lastIndexOf('.')
        return if (dot > 0) trackId.substring(0, dot) else trackId
    }

    /** 선호 컨테이너(webm 또는 mp4)를 먼저, 그다음 비트레이트 높은 순. [language]가 있으면 그 언어 트랙만. */
    fun orderAudio(all: List<YtFormat>, preferWebm: Boolean, language: String?): List<YtFormat> {
        val preferred = if (preferWebm) "webm" else "mp4"
        return all
            .filter { it.isAudioOnly }
            .filter { language == null || (it.trackId != null && languageId(it.trackId) == language) }
            .sortedWith(
                compareByDescending<YtFormat> { if (it.container == preferred) 1 else 0 }
                    .thenByDescending { it.bitrate },
            )
    }

    /**
     * 영상 하나. 소리 든 형식이 [maxHeight] 이하에 있고 더 큰 영상 전용 mp4가 없으면 소리 든 형식(한 플레이어로 튼다),
     * 아니면 [maxHeight] 이하 mp4 영상 전용 가운데 가장 큰 것. 없으면 null.
     * 돌려주는 두 번째 값은 소리 든 형식인지.
     */
    fun pickVideo(all: List<YtFormat>, maxHeight: Int): Pair<YtFormat, Boolean>? {
        val muxed = all.filter { it.muxed && it.isVideo && it.height <= maxHeight }.sortedByDescending { it.height }
        val only = all
            .filter { !it.muxed && it.isVideo && it.container == "mp4" && it.height <= maxHeight }
            .sortedByDescending { it.height }
        return if (muxed.isNotEmpty() && (only.isEmpty() || only.first().height <= muxed.first().height)) {
            muxed.first() to true
        } else {
            only.firstOrNull()?.let { it to false }
        }
    }

    /** 언어 트랙 목록 (id 중복 없이, 처음 나온 순). */
    fun languages(all: List<YtFormat>): List<Triple<String, String, Boolean>> {
        val byId = LinkedHashMap<String, Triple<String, String, Boolean>>()
        for (f in all) {
            val id = f.trackId ?: continue
            val lang = languageId(id)
            if (!byId.containsKey(lang)) byId[lang] = Triple(lang, f.trackName ?: lang, f.trackDefault)
        }
        return byId.values.toList()
    }
}
