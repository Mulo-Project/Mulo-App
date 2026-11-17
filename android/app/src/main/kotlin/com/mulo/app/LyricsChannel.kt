package com.mulo.app

import android.content.Context
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import java.io.File
import java.util.concurrent.Executors

/**
 * 가사 (`music_app/lyrics`): `read`(uri → 파일 태그 속 가사 글 또는 null)를 네이티브가 한다. Dart는 형식을 모르고 주소만 넘긴다.
 * mp3는 [Id3Lyrics](USLT · TXXX), 그 밖의 형식은 [TagReader]가 읽은 `lyrics` 칸(Vorbis 코멘트 등)을 쓴다.
 */
class LyricsChannel(private val context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME) {
    private val io = Executors.newSingleThreadExecutor()

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> {
                    val uri = call.arguments as? String
                    if (uri.isNullOrEmpty()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    runAsync(io, result, "read_failed") { read(uri) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun open(uri: String): java.io.InputStream? = when {
        uri.startsWith("content://") -> context.contentResolver.openInputStream(Uri.parse(uri))
        uri.startsWith("file://") -> File(Uri.parse(uri).path ?: "").takeIf { it.exists() }?.inputStream()
        uri.contains("://") -> null
        else -> File(uri).takeIf { it.exists() }?.inputStream()
    }

    /** 태그 속 가사. 형식이 모르는 것이거나 가사가 없으면 null. */
    @androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
    private fun read(uri: String): String? {
        val id3 = open(uri)?.use { input ->
            val head = ByteArray(10)
            var n = 0
            while (n < head.size) {
                val r = input.read(head, n, head.size - n)
                if (r < 0) break
                n += r
            }
            val length = if (n == head.size) Id3Lyrics.tagLength(head) else null
            // 커버가 든 태그도 읽되, 비정상적으로 큰 것은 건너뛴다.
            if (length == null || length > 32 * 1024 * 1024) {
                null
            } else {
                val tag = head.copyOf(length)
                var got = 10
                while (got < length) {
                    val r = input.read(tag, got, length - got)
                    if (r < 0) break
                    got += r
                }
                Id3Lyrics.parse(tag.copyOf(got))
            }
        }
        if (id3 != null) return id3
        // mp3가 아니거나 ID3에 가사가 없으면: Media3가 읽는 칸 (Vorbis 코멘트 · mp4 등).
        return try {
            TagReader.read(context, uri)["lyrics"]?.trim()?.takeIf { it.isNotEmpty() }
        } catch (e: Exception) {
            MuloLog.d(MuloLog.NATIVE, "MuloTag lyrics read failed: ${e.message}")
            null
        }
    }

    override fun dispose() {
        super.dispose()
        io.shutdown()
    }

    companion object {
        const val NAME = "music_app/lyrics"
    }
}
