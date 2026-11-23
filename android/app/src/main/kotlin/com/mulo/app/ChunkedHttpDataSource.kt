package com.mulo.app

import android.net.Uri
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.TransferListener

/**
 * 한 번에 길게 요청하지 않고 [chunk] 크기의 구간(Range)으로 나눠 요청하는 HTTP 데이터 소스.
 * 유튜브 서버는 길게 이어지는 한 연결의 속도를 얼마 뒤 깎아서, 재생 중 갑자기 오래 멈추기 때문이다.
 * 조각이 끝나면 다음 구간을 이어서 요청하고, 위로는 하나의 연속된 스트림으로 보인다.
 * 서버가 구간 요청을 무시하고 전체를 주면(206이 아님 · `Content-Range` 없음) 그대로 읽는다.
 */
@UnstableApi
internal class ChunkedHttpDataSource(
    private val source: DataSource,
    private val chunk: Long,
) : DataSource {
    private var spec: DataSpec? = null
    private var position = 0L

    /** 전체 요청에서 아직 안 읽은 바이트. 모르면 [C.LENGTH_UNSET]. */
    private var remaining = C.LENGTH_UNSET.toLong()

    /** 지금 열려 있는 조각에서 아직 안 읽은 바이트. */
    private var chunkRemaining = 0L
    private var passthrough = false
    private var opened = false

    override fun addTransferListener(listener: TransferListener) = source.addTransferListener(listener)

    private fun openChunk(base: DataSpec, from: Long, length: Long): Long {
        val spec = base.buildUpon().setPosition(from).setLength(length).build()
        opened = true
        return source.open(spec)
    }

    override fun open(dataSpec: DataSpec): Long {
        spec = dataSpec
        position = dataSpec.position
        passthrough = false
        val ask = if (dataSpec.length != C.LENGTH_UNSET.toLong()) minOf(chunk, dataSpec.length) else chunk
        val n = openChunk(dataSpec, position, ask)
        val total = totalFromContentRange()
        if (total == null) {
            // 구간 요청이 받아들여지지 않았다: 열린 응답을 그대로 끝까지 읽는다.
            passthrough = true
            return n
        }
        remaining = if (dataSpec.length != C.LENGTH_UNSET.toLong()) dataSpec.length else total - dataSpec.position
        chunkRemaining = n
        return remaining
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        if (length == 0) return 0
        if (passthrough) return source.read(buffer, offset, length)
        if (remaining == 0L) return C.RESULT_END_OF_INPUT
        if (chunkRemaining == 0L) {
            // 이 조각을 다 읽었다: 이어서 다음 구간을 새로 요청한다.
            source.close()
            val base = spec ?: return C.RESULT_END_OF_INPUT
            val ask = if (remaining != C.LENGTH_UNSET.toLong()) minOf(chunk, remaining) else chunk
            chunkRemaining = openChunk(base, position, ask)
            if (chunkRemaining == 0L) return C.RESULT_END_OF_INPUT
        }
        val want = if (chunkRemaining == C.LENGTH_UNSET.toLong()) length else minOf(length.toLong(), chunkRemaining).toInt()
        val read = source.read(buffer, offset, want)
        if (read == C.RESULT_END_OF_INPUT) return C.RESULT_END_OF_INPUT
        position += read
        if (chunkRemaining != C.LENGTH_UNSET.toLong()) chunkRemaining -= read
        if (remaining != C.LENGTH_UNSET.toLong()) remaining -= read
        return read
    }

    /** 응답 머리글 `Content-Range: bytes 0-1023/12345`의 전체 크기. 없거나 `*`면 null. */
    private fun totalFromContentRange(): Long? {
        val headers = source.responseHeaders
        val value = headers.entries.firstOrNull { it.key.equals("Content-Range", ignoreCase = true) }
            ?.value?.firstOrNull() ?: return null
        return value.substringAfterLast('/', "").toLongOrNull()
    }

    override fun getUri(): Uri? = source.uri

    override fun getResponseHeaders(): Map<String, List<String>> = source.responseHeaders

    override fun close() {
        if (opened) {
            opened = false
            source.close()
        }
        spec = null
    }
}
