package com.mulo.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TagChannelTest {
    @Test
    fun shapeValuesDropsBlanksAndAddsCoverColor() {
        val v = TagChannel.shapeValues(mapOf("title" to "제목", "album" to null, "artist" to "  "), 0xFF112233L)
        assertEquals(mapOf("title" to "제목", "COVER_COLOR" to "ff112233"), v)
        assertEquals(emptyMap<String, String>(), TagChannel.shapeValues(null, null))
    }

    @Test
    fun parsesCoverColorBack() {
        assertEquals(0xFF00AAFFL, TagChannel.parseCoverColor(TagChannel.shapeValues(null, 0xFF00AAFFL)))
        assertEquals(0xFF112233L, TagChannel.parseCoverColor(mapOf("cover_color" to " ff112233 ")))
        assertNull(TagChannel.parseCoverColor(emptyMap()))
        assertNull(TagChannel.parseCoverColor(mapOf("cover_color" to "zz")))
    }
}
