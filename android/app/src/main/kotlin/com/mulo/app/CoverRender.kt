package com.mulo.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import java.io.File

/**
 * 파일 태그에 넣을 커버: 고른 확대 · 위치 · 각도대로 검정 바탕의 정사각형 PNG로 만든다.
 * 앱 안 커버(Dart `paintCover`)와 같은 규칙이다: 가로 / 세로 비율로 칸에 맞춘 크기에 배율을 곱하고,
 * 중심을 (0.5 + dx, 0.5 + dy)에 두고 시계 방향으로 돌린다. 형식과 무관해 태그 형식 함수에는 완성된 PNG만 넘어간다.
 */
object CoverRender {
    private const val MIN_SCALE = 0.2
    private const val MAX_SCALE = 5.0
    private const val MAX_OFFSET = 1.0

    /** [source] 이미지 파일을 [side]px 정사각형 PNG로 [out]에 쓴다. 이미지를 못 읽으면 false. */
    fun render(source: String, scale: Double, dx: Double, dy: Double, rotation: Double, side: Int, out: File): Boolean {
        val image = BitmapFactory.decodeFile(source) ?: return false
        val bitmap = Bitmap.createBitmap(side, side, Bitmap.Config.ARGB_8888)
        try {
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.BLACK)
            val s = scale.coerceIn(MIN_SCALE, MAX_SCALE)
            val ox = dx.coerceIn(-MAX_OFFSET, MAX_OFFSET)
            val oy = dy.coerceIn(-MAX_OFFSET, MAX_OFFSET)
            var r = rotation % 360
            if (r > 180) r -= 360
            if (r < -180) r += 360
            val aspect = image.width.toDouble() / image.height
            val fw = if (aspect >= 1) aspect else 1.0
            val fh = if (aspect >= 1) 1.0 else 1 / aspect
            val w = (fw * s * side).toFloat()
            val h = (fh * s * side).toFloat()
            canvas.save()
            canvas.translate(((.5 + ox) * side).toFloat(), ((.5 + oy) * side).toFloat())
            canvas.rotate(r.toFloat())
            val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
            canvas.drawBitmap(image, null, RectF(-w / 2, -h / 2, w / 2, h / 2), paint)
            canvas.restore()
            out.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            return out.length() > 0
        } finally {
            image.recycle()
            bitmap.recycle()
        }
    }
}
