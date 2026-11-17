package com.mulo.app

/**
 * mp3 ID3v2 태그 속 가사를 꺼낸다 (mp3 전용 함수). 표준 가사 칸(USLT)과, ffmpeg · 다른 도구가 쓰는
 * 사용자 정의 칸(TXXX, 설명이 `LYRICS` 또는 `USLT`)을 모두 본다. ID3v2.3 · 2.4를 지원하고, 없거나 깨졌으면 null.
 */
object Id3Lyrics {
    /** 태그 머리(10바이트)에서 태그 전체 길이(머리 포함). ID3 태그가 아니면 null. */
    fun tagLength(head: ByteArray): Int? {
        if (head.size < 10 || head[0] != 0x49.toByte() || head[1] != 0x44.toByte() || head[2] != 0x33.toByte()) return null
        return 10 + syncsafe(head, 6)
    }

    /** [tag]: 머리를 포함한 ID3v2 태그 바이트. */
    fun parse(tag: ByteArray): String? {
        val length = tagLength(tag) ?: return null
        val version = tag[3].toInt()
        if (version != 3 && version != 4) return null
        val end = minOf(length, tag.size)
        var pos = 10
        if (tag[5].toInt() and 0x40 != 0 && pos + 4 <= end) {
            // 확장 머리: 2.4는 길이에 자기 자신(4바이트)이 들어 있고, 2.3은 들어 있지 않다.
            pos += if (version == 4) syncsafe(tag, pos) else u32(tag, pos) + 4
        }
        var txxx: String? = null
        while (pos + 10 <= end) {
            if (tag[pos].toInt() == 0) break // 채움 구간
            val id = String(tag, pos, 4, Charsets.ISO_8859_1)
            val size = if (version == 4) syncsafe(tag, pos + 4) else u32(tag, pos + 4)
            val body = pos + 10
            if (size <= 0 || body + size > end) break
            when (id) {
                // 표준 칸이 있으면 그것이 우선이다.
                "USLT" -> uslt(tag.copyOfRange(body, body + size))?.let { return it }
                "TXXX" -> if (txxx == null) txxx = txxx(tag.copyOfRange(body, body + size))
            }
            pos = body + size
        }
        return txxx
    }

    private fun uslt(b: ByteArray): String? {
        if (b.size < 5) return null
        val enc = b[0].toInt()
        // 언어 3바이트 다음에 설명(끝 표시까지), 그 뒤가 가사 글이다.
        val (_, next) = readTerminated(b, 4, enc)
        return clean(decode(b.copyOfRange(minOf(next, b.size), b.size), enc))
    }

    private fun txxx(b: ByteArray): String? {
        if (b.size < 2) return null
        val enc = b[0].toInt()
        val (description, next) = readTerminated(b, 1, enc)
        val name = description.trim().uppercase()
        if (name != "LYRICS" && name != "USLT") return null
        return clean(decode(b.copyOfRange(minOf(next, b.size), b.size), enc))
    }

    private fun clean(s: String) = s.replace("\u0000", "").trim().ifEmpty { null }

    private fun wide(enc: Int) = enc == 1 || enc == 2

    /** [start]부터 끝 표시(1바이트 0 · 2바이트 0)까지 읽은 글과 그 다음 위치. */
    private fun readTerminated(b: ByteArray, start: Int, enc: Int): Pair<String, Int> {
        var i = start
        if (wide(enc)) {
            while (i + 1 < b.size && !(b[i].toInt() == 0 && b[i + 1].toInt() == 0)) i += 2
            return decode(b.copyOfRange(start, minOf(i, b.size)), enc) to i + 2
        }
        while (i < b.size && b[i].toInt() != 0) i++
        return decode(b.copyOfRange(start, i), enc) to i + 1
    }

    private fun decode(b: ByteArray, enc: Int): String = when (enc) {
        0 -> String(b, Charsets.ISO_8859_1)
        3 -> String(b, Charsets.UTF_8)
        1 -> when {
            b.size >= 2 && b[0] == 0xFF.toByte() && b[1] == 0xFE.toByte() -> String(b, 2, b.size - 2, Charsets.UTF_16LE)
            b.size >= 2 && b[0] == 0xFE.toByte() && b[1] == 0xFF.toByte() -> String(b, 2, b.size - 2, Charsets.UTF_16BE)
            else -> String(b, Charsets.UTF_16BE)
        }
        2 -> String(b, Charsets.UTF_16BE)
        else -> ""
    }

    private fun syncsafe(b: ByteArray, i: Int) =
        ((b[i].toInt() and 0x7F) shl 21) or ((b[i + 1].toInt() and 0x7F) shl 14) or ((b[i + 2].toInt() and 0x7F) shl 7) or (b[i + 3].toInt() and 0x7F)

    private fun u32(b: ByteArray, i: Int) =
        ((b[i].toInt() and 0xFF) shl 24) or ((b[i + 1].toInt() and 0xFF) shl 16) or ((b[i + 2].toInt() and 0xFF) shl 8) or (b[i + 3].toInt() and 0xFF)
}
