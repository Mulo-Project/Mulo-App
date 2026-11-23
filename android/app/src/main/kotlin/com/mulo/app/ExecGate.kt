package com.mulo.app

import java.util.concurrent.CountDownLatch

/**
 * yt-dlp 호출을 한 번에 하나씩, 우선순위(작을수록 먼저)와 들어온 순서대로 돌린다.
 * yt-dlp가 겹쳐 돌면 휴대폰에서 서로 느려진다 (혼자 4초인 것이 둘이 겹치면 16초 넘게 걸렸다).
 * 우선순위: 0 소리 주소(소리가 먼저 나게) → 1 영상 주소 → 2 곡 정보 · 소리 언어 목록 같은 나머지.
 */
class ExecGate {
    /** 같은 [group]의 더 새로운 요청이 와서 줄에서 빠진 일. */
    class SupersededException : Exception("superseded")

    private class Waiter(val priority: Int, val group: String?) {
        val latch = CountDownLatch(1)

        @Volatile var superseded = false
    }

    private val lock = Any()
    private var running = false
    private val waiting = ArrayList<Waiter>()

    /**
     * [task]를 차례가 되면 돌린다. [group]이 같은 대기 중인 일은 가장 나중에 온 것만 남긴다
     * (예전 상세 화면을 위한 읽기가 줄을 서서 지금 필요한 읽기를 늦추지 않게).
     */
    fun <T> run(priority: Int, group: String? = null, task: () -> T): T {
        val waiter: Waiter? = synchronized(lock) {
            if (running) {
                if (group != null) {
                    val it = waiting.iterator()
                    while (it.hasNext()) {
                        val w = it.next()
                        if (w.group == group) {
                            it.remove()
                            w.superseded = true
                            w.latch.countDown()
                        }
                    }
                }
                Waiter(priority, group).also { waiting.add(it) }
            } else {
                running = true
                null
            }
        }
        if (waiter != null) {
            waiter.latch.await()
            if (waiter.superseded) throw SupersededException()
        }
        try {
            return task()
        } finally {
            next()
        }
    }

    private fun next() {
        synchronized(lock) {
            if (waiting.isEmpty()) {
                running = false
                return
            }
            var best = 0
            for (i in 1 until waiting.size) if (waiting[i].priority < waiting[best].priority) best = i
            waiting.removeAt(best).latch.countDown()
        }
    }
}
