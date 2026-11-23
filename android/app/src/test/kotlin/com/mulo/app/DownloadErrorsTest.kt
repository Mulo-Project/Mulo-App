package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DownloadErrorsTest {
    @Test
    fun noSpaceMessagesAreRecognized() {
        assertTrue(DownloadErrors.isNoSpace("java.io.IOException: write failed: ENOSPC (No space left on device)"))
        assertTrue(DownloadErrors.isNoSpace("no space left on device"))
        assertFalse(DownloadErrors.isNoSpace("HTTP 403 (구간 0)"))
    }

    @Test
    fun friendlyReplacesOnlyNoSpace() {
        assertEquals("저장 공간이 부족해요", DownloadErrors.friendly("write failed: ENOSPC (No space left on device)"))
        assertEquals("HTTP 403", DownloadErrors.friendly("HTTP 403"))
    }
}
