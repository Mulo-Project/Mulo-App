package com.mulo.app

/**
 * 구간(A-B) 반복의 상태: 현재 곡의 [startMs, endMs]. 곡이 바뀌면 [PlaybackHub]가 푼다.
 * 위치를 재서 되감는 일(타이머 · seek)은 [PlaybackHub]가 한다.
 */
internal class AbLoop {
    var startMs = -1L
        private set
    var endMs = -1L
        private set

    val active get() = startMs >= 0

    /** 구간을 정한다. 둘 중 하나라도 null이거나 구간이 비정상이면 해제. */
    fun set(startMs: Long?, endMs: Long?) {
        if (startMs == null || endMs == null || startMs < 0 || endMs <= startMs) {
            this.startMs = -1L
            this.endMs = -1L
        } else {
            this.startMs = startMs
            this.endMs = endMs
        }
    }

    /** 지금 위치가 끝 지점에 닿았거나 지났으면 되감을 시작 지점, 아니면 null. */
    fun wrapTarget(positionMs: Long): Long? = if (active && positionMs >= endMs) startMs else null
}
