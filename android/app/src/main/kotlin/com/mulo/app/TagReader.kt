package com.mulo.app

import android.content.Context
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.MetadataRetriever
import androidx.media3.extractor.metadata.id3.TextInformationFrame
import androidx.media3.container.MdtaMetadataEntry
import androidx.media3.extractor.metadata.vorbis.VorbisComment
import java.util.concurrent.TimeUnit

/**
 * 곡 파일의 태그를 안드로이드(Media3)가 직접 읽는다. 파일을 복사하지 않고 주소로 바로 읽고, ffmpeg가 없는 빌드도 된다.
 * 기본 칸(제목 · 아티스트 · 앨범 · 장르)은 형식마다 Media3가 알아서 옮기고, 사용자 정의 칸(앱 전용 `COVER_*`)은
 * mp3의 TXXX · opus · ogg의 Vorbis 코멘트 · mp4의 mdta 칸에서 꺼낸다. 키는 모두 소문자.
 */
@UnstableApi
object TagReader {
    fun read(context: Context, uri: String): Map<String, String> {
        val item = MediaItem.fromUri(if (uri.startsWith("content://")) Uri.parse(uri) else Uri.fromFile(java.io.File(uri)))
        val groups = MetadataRetriever.retrieveMetadata(context, item).get(15, TimeUnit.SECONDS)
        val out = linkedMapOf<String, String>()
        val standard = MediaMetadata.Builder()
        for (g in 0 until groups.length) {
            val metadata = groups.get(g).getFormat(0).metadata ?: continue
            for (i in 0 until metadata.length()) {
                val entry = metadata.get(i)
                entry.populateMediaMetadata(standard)
                when (entry) {
                    is TextInformationFrame ->
                        if (entry.id == "TXXX") entry.description?.let { d -> entry.values.firstOrNull()?.let { out.putIfAbsent(d.lowercase(), it) } }
                    is VorbisComment -> out.putIfAbsent(entry.key.lowercase(), entry.value)
                    is MdtaMetadataEntry -> if (entry.typeIndicator == MdtaMetadataEntry.TYPE_INDICATOR_STRING) {
                        out.putIfAbsent(entry.key.lowercase().substringAfterLast('.'), String(entry.value, Charsets.UTF_8))
                    }
                    else -> {}
                }
            }
        }
        val m = standard.build()
        mapOf(
            "title" to m.title,
            "artist" to m.artist,
            "album" to m.albumTitle,
            "genre" to m.genre,
        ).forEach { (k, v) -> v?.toString()?.takeIf { it.isNotBlank() }?.let { out[k] = it } }
        MuloLog.d(MuloLog.NATIVE, "MuloTag read keys=${out.keys}")
        return out
    }
}
