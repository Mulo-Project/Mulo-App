package com.mulo.app

/** 영상 자막 줄(`ms` · `text`)을 싱크 가사(.lrc) 글로 바꾼다 (예전 Dart `SubtitleTrack.toLrc` · `withoutSoundCues`). */
object SubtitleLrc {
    private val soundOnly = Regex("^[\\s♪♫♬♩\\-–]*$")
    private val soundTag = Regex("^[\\[\\(（【][^\\]\\)）】]*[\\]\\)）】]$")

    /** 글 전체가 `[Music]` · `(박수)` · `♪` 같은 효과음 표시인 줄. */
    private fun isSoundCue(text: String): Boolean {
        val t = text.trim()
        return soundOnly.matches(t) || soundTag.matches(t)
    }

    /** 시간 순으로 `[mm:ss.xx]글` 한 줄씩. 빈 줄은 건너뛴다. [skipSounds]면 효과음 줄도 뺀다. */
    fun toLrc(cues: List<Map<String, Any?>>, skipSounds: Boolean): String {
        val b = StringBuilder()
        for (c in cues) {
            val text = (c["text"] as? String ?: "").trim()
            if (text.isEmpty() || (skipSounds && isSoundCue(text))) continue
            val ms = (c["ms"] as? Number)?.toLong() ?: continue
            val mm = (ms / 60000).toString().padStart(2, '0')
            val ss = ((ms / 1000) % 60).toString().padStart(2, '0')
            val cs = ((ms % 1000) / 10).toString().padStart(2, '0')
            b.append('[').append(mm).append(':').append(ss).append('.').append(cs).append(']').append(text).append('\n')
        }
        return b.toString().trimEnd()
    }
}
