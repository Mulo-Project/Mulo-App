package com.mulo.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Handler
import android.os.Looper
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread
import kotlin.math.abs
import kotlin.math.min

/**
 * 알림의 큰 아이콘 자리에 넣을 이미지. 웹 주소는 백그라운드에서 받아 정사각형으로 잘라 한 장만 기억해 둔다
 * (진행 알림은 자주 다시 그려지므로 매번 받지 않는다).
 * 아직 없으면 null을 돌려주고, 불러오면 [onLoaded]로 알림을 다시 그리게 한다. 못 받은 주소는 다시 시도하지 않는다.
 */
object NotificationArt {
    private const val SIZE = 256
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var cachedUrl: String? = null

    @Volatile
    private var cachedBitmap: Bitmap? = null
    private val loading = HashSet<String>()
    private val failed = HashSet<String>()

    /** [uri]의 이미지를 돌려준다. 아직 불러오는 중이면 null (다 불러오면 [onLoaded]를 부른다). */
    fun get(uri: String?, onLoaded: () -> Unit): Bitmap? {
        if (uri.isNullOrEmpty()) return null
        if (cachedUrl == uri) return cachedBitmap
        // 파일은 바로 읽는다 (작고 빠르다).
        if (!uri.startsWith("http")) return decodeFile(uri)?.also { remember(uri, it) }
        synchronized(loading) {
            if (uri in failed || !loading.add(uri)) return null
        }
        thread(name = "notification-art") {
            val bitmap = try {
                download(uri)
            } catch (e: Exception) {
                null
            }
            synchronized(loading) {
                loading.remove(uri)
                if (bitmap == null) failed.add(uri)
            }
            if (bitmap != null) {
                remember(uri, bitmap)
                main.post(onLoaded)
            }
        }
        return null
    }

    /** 이미지를 바로 받아 돌려준다 (백그라운드 스레드에서만 부른다). 못 받으면 null. */
    fun loadBlocking(uri: String?): Bitmap? {
        if (uri.isNullOrEmpty()) return null
        return try {
            if (uri.startsWith("http")) download(uri) else decodeFile(uri)
        } catch (e: Exception) {
            null
        }
    }

    private fun remember(uri: String, bitmap: Bitmap) {
        cachedBitmap = bitmap
        cachedUrl = uri
    }

    private fun download(url: String): Bitmap? {
        val conn = URL(url).openConnection() as HttpURLConnection
        try {
            conn.connectTimeout = 5_000
            conn.readTimeout = 5_000
            if (conn.responseCode != 200) return null
            val raw = conn.inputStream.use { BitmapFactory.decodeStream(it) } ?: return null
            return square(raw)
        } finally {
            conn.disconnect()
        }
    }

    private fun decodeFile(uri: String): Bitmap? {
        val path = if (uri.startsWith("file:")) Uri.parse(uri).path ?: return null else uri
        return BitmapFactory.decodeFile(path)?.let(::square)
    }

    /**
     * 가운데를 정사각형으로 자르고 [SIZE]로 줄인다. 4:3 유튜브 썸네일은 위아래 검은 띠가 있어 그만큼 먼저 뺀다.
     */
    private fun square(src: Bitmap): Bitmap {
        var top = 0
        var h = src.height
        if (abs(src.width.toFloat() / src.height - 4f / 3f) < 0.05f) {
            top = (src.height * 0.125f).toInt()
            h = (src.height * 0.75f).toInt()
        }
        val side = min(src.width, h)
        val left = (src.width - side) / 2
        val cropY = top + (h - side) / 2
        val cropped = Bitmap.createBitmap(src, left, cropY, side, side)
        return if (side > SIZE) Bitmap.createScaledBitmap(cropped, SIZE, SIZE, true) else cropped
    }
}
