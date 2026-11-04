package com.mulo.app

import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player

/** Dart가 보낸 값(문자열 · 맵)과 플레이어 값 사이의 변환. */
internal object QueueMapping {
    fun repeatModeOf(name: String?) = when (name) {
        "all" -> Player.REPEAT_MODE_ALL
        "one" -> Player.REPEAT_MODE_ONE
        else -> Player.REPEAT_MODE_OFF
    }

    fun repeatNameOf(mode: Int) = when (mode) {
        Player.REPEAT_MODE_ALL -> "all"
        Player.REPEAT_MODE_ONE -> "one"
        else -> "off"
    }

    /** 대기열 곡 맵 하나를 [MediaItem]으로. 표지는 곡 id로 [artById]에서 찾는다. */
    fun mediaItemOf(map: Map<*, *>, artById: Map<String, String>): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(map["title"] as? String)
            .setArtist((map["artist"] as? String)?.ifEmpty { null })
            .setAlbumTitle((map["album"] as? String)?.ifEmpty { null })
            .setDurationMs((map["durationMs"] as? Number)?.toLong()?.takeIf { it > 0 })
            .setArtworkUri((map["id"] as? String)?.let { artById[it] }?.let { Uri.parse(it) })
            .build()
        return MediaItem.Builder()
            .setMediaId(map["id"] as? String ?: "")
            .setUri(map["uri"] as? String ?: "")
            .setMediaMetadata(metadata)
            .build()
    }

    /** 저장해 둔 곡([StoredItem])을 [MediaItem]으로 되살린다. */
    fun mediaItemOf(i: StoredItem): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(i.title)
            .setArtist(i.artist.ifEmpty { null })
            .setAlbumTitle(i.album.ifEmpty { null })
            .setDurationMs(i.durationMs.takeIf { it > 0 })
            .setArtworkUri(i.art?.let { Uri.parse(it) })
            .build()
        return MediaItem.Builder().setMediaId(i.id).setUri(i.uri).setMediaMetadata(metadata).build()
    }

    /** [MediaItem]을 저장할 [StoredItem]으로. */
    fun storedItemOf(item: MediaItem) = StoredItem(
        id = item.mediaId,
        uri = item.localConfiguration?.uri?.toString() ?: "",
        title = item.mediaMetadata.title?.toString() ?: "",
        artist = item.mediaMetadata.artist?.toString() ?: "",
        album = item.mediaMetadata.albumTitle?.toString() ?: "",
        durationMs = item.mediaMetadata.durationMs ?: 0L,
        art = item.mediaMetadata.artworkUri?.toString(),
    )
}
