package com.mulo.app

/** 가사 창이 쓰는, 화면과 무관한 계산 ([LyricsOverlay]에서 분리). */
internal object LyricsTimeline {
    /** [times](오름차순, ms) 중 [position] 이하인 마지막 줄의 위치. 아직 첫 줄 전이면 -1. */
    fun indexAt(times: LongArray, position: Long): Int {
        var lo = 0
        var hi = times.size - 1
        var found = -1
        while (lo <= hi) {
            val mid = (lo + hi) ushr 1
            if (times[mid] <= position) {
                found = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return found
    }

    /** [index] 뒤의 첫 빈 줄 아닌 줄 (없으면 빈 글). */
    fun nextLineAfter(texts: List<String>, index: Int): String {
        var i = index + 1
        while (i < texts.size) {
            if (texts[i].isNotEmpty()) return texts[i]
            i++
        }
        return ""
    }

    /** 밝은 색인지 (그 위에 올릴 글자색을 검정으로 할지 정한다). */
    fun isLight(color: Int): Boolean {
        val r = (color shr 16) and 0xFF
        val g = (color shr 8) and 0xFF
        val b = color and 0xFF
        return (0.299 * r + 0.587 * g + 0.114 * b) > 150
    }
}
