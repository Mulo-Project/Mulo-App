package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class NativeVideoSaverTest {
    @get:Rule val tmp = TemporaryFolder()

    @Test
    fun readsYoutubeIdFromCommonUrls() {
        assertEquals("dQw4w9WgXcQ", NativeVideoSaver.youtubeIdOf("https://www.youtube.com/watch?v=dQw4w9WgXcQ"))
        assertEquals("dQw4w9WgXcQ", NativeVideoSaver.youtubeIdOf("https://www.youtube.com/watch?list=x&v=dQw4w9WgXcQ"))
        assertEquals("dQw4w9WgXcQ", NativeVideoSaver.youtubeIdOf("https://youtu.be/dQw4w9WgXcQ"))
        assertEquals("dQw4w9WgXcQ", NativeVideoSaver.youtubeIdOf("https://www.youtube.com/shorts/dQw4w9WgXcQ"))
        assertNull(NativeVideoSaver.youtubeIdOf("https://soundcloud.com/a/b"))
    }

    @Test
    fun leavesNonMp4AndNonYoutubeToYtDlp() {
        val saver = NativeVideoSaver({ tmp.root }, { _, _, _ -> true }, { _, _ -> error("읽으면 안 된다") })
        assertFalse(saver.save("https://youtu.be/dQw4w9WgXcQ", 720, "webm", tmp.root, "s") {})
        assertFalse(saver.save("https://soundcloud.com/a/b", 720, "mp4", tmp.root, "s") {})
    }

    @Test
    fun fallsBackWhenNoSourcesFound() {
        val saver = NativeVideoSaver({ tmp.root }, { _, _, _ -> true }, { _, _ -> null })
        assertFalse(saver.save("https://youtu.be/dQw4w9WgXcQ", 720, "mp4", File(tmp.root, "out"), "s") {})
        assertTrue(File(tmp.root, "out").listFiles().isNullOrEmpty())
    }
}
