package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Test

class SubtitleLrcTest {
    private fun cue(ms: Long, text: String) = mapOf<String, Any?>("ms" to ms, "text" to text)

    @Test
    fun writesOneLrcLinePerCue() {
        val lrc = SubtitleLrc.toLrc(listOf(cue(0, "첫 줄"), cue(61_230, "둘째 줄")), skipSounds = true)
        assertEquals("[00:00.00]첫 줄\n[01:01.23]둘째 줄", lrc)
    }

    @Test
    fun skipsEmptyLinesAndSoundCuesOnlyWhenAsked() {
        val cues = listOf(cue(0, "[음악]"), cue(1000, " "), cue(2000, "노래"), cue(3000, "♪"))
        assertEquals("[00:02.00]노래", SubtitleLrc.toLrc(cues, skipSounds = true))
        assertEquals("[00:00.00][음악]\n[00:02.00]노래\n[00:03.00]♪", SubtitleLrc.toLrc(cues, skipSounds = false))
    }
}
