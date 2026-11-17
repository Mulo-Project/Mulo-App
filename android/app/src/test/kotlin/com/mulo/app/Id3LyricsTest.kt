package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class Id3LyricsTest {
    private fun frame(id: String, body: ByteArray, v4: Boolean = false): ByteArray {
        val n = body.size
        val size = if (v4) byteArrayOf(((n shr 21) and 0x7F).toByte(), ((n shr 14) and 0x7F).toByte(), ((n shr 7) and 0x7F).toByte(), (n and 0x7F).toByte())
        else byteArrayOf((n shr 24).toByte(), (n shr 16).toByte(), (n shr 8).toByte(), n.toByte())
        return id.toByteArray(Charsets.ISO_8859_1) + size + byteArrayOf(0, 0) + body
    }

    private fun tag(vararg frames: ByteArray, version: Int = 3): ByteArray {
        val body = frames.fold(ByteArray(0)) { a, f -> a + f } + ByteArray(4)
        val n = body.size
        val head = byteArrayOf(0x49, 0x44, 0x33, version.toByte(), 0, 0, ((n shr 21) and 0x7F).toByte(), ((n shr 14) and 0x7F).toByte(), ((n shr 7) and 0x7F).toByte(), (n and 0x7F).toByte())
        return head + body
    }

    @Test
    fun readsUsltLatin1() {
        val body = byteArrayOf(0) + "eng".toByteArray() + byteArrayOf(0) + "[00:01.00]hello".toByteArray()
        assertEquals("[00:01.00]hello", Id3Lyrics.parse(tag(frame("USLT", body))))
    }

    @Test
    fun readsTxxxLyricsUtf8V24AndSkipsOtherTxxx() {
        val other = frame("TXXX", byteArrayOf(3) + "COVER_SOURCE".toByteArray() + byteArrayOf(0) + "x".toByteArray(), true)
        val lyrics = frame("TXXX", byteArrayOf(3) + "lyrics".toByteArray() + byteArrayOf(0) + "가사".toByteArray(), true)
        assertEquals("가사", Id3Lyrics.parse(tag(other, lyrics, version = 4)))
    }

    @Test
    fun readsTxxxUsltDescriptionAsLyrics() {
        val txxx = frame("TXXX", byteArrayOf(3) + "USLT".toByteArray() + byteArrayOf(0) + "[00:01.00]가나다".toByteArray())
        assertEquals("[00:01.00]가나다", Id3Lyrics.parse(tag(txxx)))
    }

    @Test
    fun nullWhenNoLyricsOrNotId3() {
        assertNull(Id3Lyrics.parse(tag(frame("TIT2", byteArrayOf(0, 0x74)))))
        assertNull(Id3Lyrics.parse(ByteArray(20) { 1 }))
    }
}
