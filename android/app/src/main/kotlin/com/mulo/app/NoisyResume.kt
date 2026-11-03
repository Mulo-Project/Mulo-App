package com.mulo.app

import android.os.SystemClock

/**
 * 이어폰 분리 · 블루투스 끊김으로 재생이 멈춘 기록과, 다시 연결됐을 때 이어 재생해도 되는지 판단.
 * 설정([enabled])이 켜져 있을 때만 이어 재생한다. 실제 재생은 [PlaybackHub]가 한다.
 */
internal class NoisyResume {
    /** 설정: 출력 기기가 다시 연결되면 이어 재생. */
    var enabled = false

    /** 그렇게 멈춘 시각 (SystemClock). 0이면 그렇게 멈춘 게 아니다. */
    private var pausedAt = 0L

    fun markPaused() {
        pausedAt = SystemClock.elapsedRealtime()
    }

    fun clear() {
        pausedAt = 0L
    }

    /**
     * 출력 기기가 새로 연결됐을 때 이어 재생해도 되는지.
     * 오래 전에 멈춘 재생이 갑자기 켜지지 않게 [RESUME_WINDOW_MS] 안에 다시 연결됐을 때만 true이고, 지났으면 기록도 비운다.
     */
    fun shouldResume(dismissed: Boolean, hasQueue: Boolean, headsetAdded: Boolean): Boolean {
        if (!enabled || pausedAt == 0L || dismissed || !hasQueue) return false
        if (!headsetAdded) return false
        if (SystemClock.elapsedRealtime() - pausedAt > RESUME_WINDOW_MS) {
            pausedAt = 0L
            return false
        }
        return true
    }

    private companion object {
        const val RESUME_WINDOW_MS = 10 * 60 * 1000L
    }
}
