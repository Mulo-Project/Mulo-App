package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

class ExecGateTest {
    @Test
    fun runsWaitingTasksByPriorityThenArrival() {
        val gate = ExecGate()
        val release = CountDownLatch(1)
        val started = CountDownLatch(1)
        val order = java.util.Collections.synchronizedList(ArrayList<String>())
        val first = thread {
            gate.run(2) {
                started.countDown()
                release.await()
                order.add("first")
            }
        }
        assertTrue(started.await(2, TimeUnit.SECONDS))
        val waiters = listOf("info" to 2, "audio" to 0, "video" to 1).map { (name, priority) ->
            val t = thread { gate.run(priority) { order.add(name) } }
            Thread.sleep(50) // 들어온 순서를 고정한다
            t
        }
        release.countDown()
        (listOf(first) + waiters).forEach { it.join(2000) }
        assertEquals(listOf("first", "audio", "video", "info"), order)
    }

    @Test
    fun newerRequestInSameGroupSupersedesWaitingOne() {
        val gate = ExecGate()
        val release = CountDownLatch(1)
        val started = CountDownLatch(1)
        val ran = java.util.Collections.synchronizedList(ArrayList<String>())
        var superseded = false
        val blocker = thread {
            gate.run(2) { started.countDown(); release.await() }
        }
        assertTrue(started.await(2, TimeUnit.SECONDS))
        val old = thread {
            try {
                gate.run(1, "video") { ran.add("old") }
            } catch (_: ExecGate.SupersededException) {
                superseded = true
            }
        }
        Thread.sleep(50)
        val fresh = thread { gate.run(1, "video") { ran.add("new") } }
        Thread.sleep(50)
        release.countDown()
        listOf(blocker, old, fresh).forEach { it.join(2000) }
        assertTrue(superseded)
        assertEquals(listOf("new"), ran)
    }
}
