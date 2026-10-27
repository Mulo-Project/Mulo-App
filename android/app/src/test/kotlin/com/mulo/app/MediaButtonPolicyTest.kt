package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MediaButtonPolicyTest {
    @Test
    fun ignoresWhenGated() {
        assertNull(MediaButtonPolicy.plan(gated = true, dismissed = true, hasQueue = true, hasInfo = true))
    }

    @Test
    fun ignoresWithoutQueue() {
        assertNull(MediaButtonPolicy.plan(gated = false, dismissed = false, hasQueue = false, hasInfo = true))
    }

    @Test
    fun pausedWithNotificationJustShowsIt() {
        val plan = MediaButtonPolicy.plan(gated = false, dismissed = false, hasQueue = true, hasInfo = true)
        assertNotNull(plan)
        assertFalse(plan!!.revive)
        assertFalse(plan.fillInfoFromQueue)
        assertTrue(plan.showNotification)
    }

    @Test
    fun appTurnedNotificationOffStillGetsPlayableSession() {
        // 앱이 setSession(null)을 보낸 뒤(알림 설정 끔)에도 버튼이 서비스를 깨웠다면 재생할 수 있어야 한다.
        val plan = MediaButtonPolicy.plan(gated = false, dismissed = false, hasQueue = true, hasInfo = false)!!
        assertTrue(plan.fillInfoFromQueue)
        assertTrue(plan.showNotification)
    }

    @Test
    fun dismissedButAllowedRevives() {
        val plan = MediaButtonPolicy.plan(gated = false, dismissed = true, hasQueue = true, hasInfo = true)!!
        assertTrue(plan.revive)
        assertEquals(true, plan.showNotification)
    }
}
