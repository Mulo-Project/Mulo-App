package com.mulo.app

import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * 유튜브 영상 저장을 yt-dlp 없이 한다: 재생에 쓰는 네이티브 resolver([YoutubeResolver])가 읽은 주소를 같은 헤더로 받아
 * (영상 + 소리 두 파일이면) ffmpeg로 이어 붙인다. yt-dlp는 주소는 찾아도 받는 단계에서 403이 나는 일이 있어, 이 방법을 먼저 쓴다.
 * 안 되면(유튜브가 아니거나 mp4가 아니거나 못 받으면) false/예외라서 호출한 쪽이 yt-dlp로 넘어간다.
 */
class NativeVideoSaver(
    private val tempDir: () -> File,
    /** 영상 · 소리(없을 수 있다) · 출력 파일을 하나로 합친다. 못 하면 false (lite는 ffmpeg가 없다). */
    private val mux: (video: File, audio: File?, output: File) -> Boolean,
    private val sources: (videoId: String, maxHeight: Int) -> YoutubeResolver.SaveSources? = YoutubeResolver::saveSources,
) {
    /** 저장했으면 true. 이 방법을 쓸 수 없는 주소 · 형식이면 false. 받다가 실패하면 예외 (둘 다 yt-dlp로 넘어간다). */
    fun save(url: String, maxHeight: Int, extension: String, dir: File, stem: String, onProgress: (Double) -> Unit): Boolean {
        if (extension != "mp4") return false // webm은 형식 조합이 달라 yt-dlp가 한다
        val id = youtubeIdOf(url) ?: return false
        val picked = sources(id, maxHeight) ?: return false
        val work = File(tempDir(), "save_${System.nanoTime()}")
        try {
            work.mkdirs()
            val total = (picked.video.contentLength + (picked.audio?.contentLength ?: 0L)).coerceAtLeast(1L)
            var done = 0L
            val report = { n: Long -> done += n; onProgress((done.toDouble() / total * 0.95).coerceAtMost(0.95)) }
            val video = File(work, "v.mp4")
            download(picked.video, video, report)
            val audio = picked.audio?.let { File(work, "a.m4a").also { f -> download(it, f, report) } }
            dir.mkdirs()
            val out = File(dir, "$stem.mp4")
            if (!mux(video, audio, out) || out.length() == 0L) {
                out.delete()
                throw IOException("합치기 실패")
            }
            onProgress(1.0)
            return true
        } finally {
            work.deleteRecursively()
        }
    }

    private fun download(f: YtFormat, dest: File, onBytes: (Long) -> Unit) {
        if (f.contentLength <= 0L) throw IOException("크기를 모른다")
        StreamDownloader.download(f.url, YoutubeResolver.headersFor(f.url), f.contentLength, dest, onBytes)
    }

    companion object {
        private val ID = Regex("""(?:youtube\.com/(?:watch\?(?:.*&)?v=|shorts/|embed/|live/)|youtu\.be/)([A-Za-z0-9_-]{11})""")

        /** 유튜브 주소에서 영상 id. 유튜브가 아니면 null. */
        fun youtubeIdOf(url: String): String? = ID.find(url)?.groupValues?.get(1)
    }
}

/** 주소를 4MB씩 Range로 나눠 받는다 (한 번에 크게 요청하면 유튜브가 끊는다). */
object StreamDownloader {
    private const val CHUNK = 4L * 1024 * 1024

    fun download(url: String, headers: Map<String, String>, length: Long, dest: File, onBytes: (Long) -> Unit) {
        dest.parentFile?.mkdirs()
        dest.outputStream().buffered().use { out ->
            var pos = 0L
            val buffer = ByteArray(64 * 1024)
            while (pos < length) {
                val end = minOf(pos + CHUNK, length) - 1
                val conn = URL(url).openConnection() as HttpURLConnection
                try {
                    conn.connectTimeout = 10_000
                    conn.readTimeout = 20_000
                    headers.forEach { (k, v) -> conn.setRequestProperty(k, v) }
                    conn.setRequestProperty("Range", "bytes=$pos-$end")
                    val code = conn.responseCode
                    if (code != 206 && code != 200) throw IOException("HTTP $code")
                    var got = 0L
                    conn.inputStream.use { input ->
                        while (true) {
                            val n = input.read(buffer)
                            if (n < 0) break
                            out.write(buffer, 0, n)
                            got += n
                            onBytes(n.toLong())
                        }
                    }
                    if (got == 0L) throw IOException("빈 응답")
                    pos += got
                } finally {
                    conn.disconnect()
                }
            }
        }
    }
}
