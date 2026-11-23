package com.mulo.app

/**
 * 태그를 읽고 쓰는 파일 형식을 정한다. 형식 구분은 앱에서 여기 한 곳에서만 한다 (Dart는 형식을 모른다).
 * 형식 이름은 [TranscoderChannel]의 형식별 함수(tagMp3 · tagOgg · tagMp4 · tagWebm · tagM4a)와 같다.
 */
object TagFormats {
    const val MP3 = "mp3"
    const val OGG = "ogg" // opus · ogg · 받은 그대로의 오디오 webm(weba)
    const val MP4 = "mp4" // 영상
    const val WEBM = "webm" // 영상
    const val M4A = "m4a"

    /** 파일 형식(mime)으로 구한다. 모르면 null. */
    fun ofMime(mime: String?): String? {
        val m = mime?.lowercase() ?: return null
        return when {
            m == "video/mp4" -> MP4
            m == "video/webm" -> WEBM
            Regex("mpeg|mp3").containsMatchIn(m) -> MP3
            Regex("ogg|opus|audio/webm").containsMatchIn(m) -> OGG
            Regex("audio/mp4|m4a|aac").containsMatchIn(m) -> M4A
            else -> null
        }
    }

    /** 확장자(점 없이)로 구한다. 모르면 null. 오디오 webm은 `weba`, 영상 webm은 `webm`이다. */
    fun ofExtension(extension: String?): String? = when (extension?.lowercase()?.trimStart('.')) {
        "mp3" -> MP3
        "opus", "ogg", "weba" -> OGG
        "mp4" -> MP4
        "webm" -> WEBM
        "m4a" -> M4A
        else -> null
    }
}
