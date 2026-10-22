package com.mulo.app

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView

/**
 * 다른 앱 위에 떠 있는 가사 창. 앱 화면이 보이는 동안에는 숨기고(앱 안에 가사 보기가 있다), 앱을 벗어나면 보인다.
 *
 * 가볍게 돌아가도록: 시간 붙은 가사를 한 번 받아 두고, 재생 위치는 이미 쥐고 있는 ExoPlayer에서 읽는다.
 * 다음 줄 시간에 맞춘 타이머 하나만 예약해 줄이 바뀔 때만 글자를 바꾼다 (주기적인 틱 없음).
 * 멈춤 · 앱이 보임 · 다른 곡 · 가사 없음이면 타이머를 걸지 않고 창을 뗀다.
 */
object LyricsOverlay {
    private const val PREFS = "lyrics_overlay"
    private const val KEY_Y = "y"

    private lateinit var context: Context
    private var initialized = false
    private val main = Handler(Looper.getMainLooper())

    private var trackId = ""
    private var times = LongArray(0)
    private var texts = emptyList<String>()
    private var appVisible = false

    private var view: TextView? = null
    private var attached = false
    private var shownText: String? = null

    private val tick = Runnable { refresh() }

    fun init(appContext: Context) {
        if (initialized) return
        initialized = true
        context = appContext.applicationContext
    }

    fun canDraw(): Boolean = Settings.canDrawOverlays(context)

    /** [id] 곡의 시간 붙은 가사를 받아 둔다. */
    fun show(id: String, newTimes: LongArray, newTexts: List<String>) {
        trackId = id
        times = newTimes
        texts = newTexts
        refresh()
    }

    fun hide() {
        trackId = ""
        times = LongArray(0)
        texts = emptyList()
        refresh()
    }

    /** 앱 화면이 보이거나 가려질 때 (MainActivity). */
    fun setAppVisible(visible: Boolean) {
        if (appVisible == visible) return
        appVisible = visible
        if (initialized) refresh()
    }

    /** 재생이 바뀌었을 때 (재생 · 일시정지 · 이동 · 곡 넘김). */
    fun onPlayerChanged() {
        if (initialized && times.isNotEmpty()) refresh()
    }

    private fun refresh() {
        main.removeCallbacks(tick)
        val exo = PlaybackHub.exo
        val active = times.isNotEmpty() && !appVisible && canDraw() &&
            exo.currentMediaItem?.mediaId == trackId
        if (!active) {
            detach()
            return
        }
        val position = exo.currentPosition
        val index = currentIndex(position)
        val text = if (index >= 0) texts[index] else ""
        if (text.isEmpty()) hideView() else showText(text)
        if (exo.isPlaying) {
            val next = index + 1
            if (next < times.size) {
                val speed = exo.playbackParameters.speed.coerceAtLeast(0.1f)
                val wait = ((times[next] - position) / speed).toLong().coerceAtLeast(30L)
                main.postDelayed(tick, wait)
            }
        }
    }

    private fun currentIndex(position: Long): Int {
        var lo = 0
        var hi = times.size - 1
        var found = -1
        while (lo <= hi) {
            val mid = (lo + hi) ushr 1
            if (times[mid] <= position) {
                found = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return found
    }

    private fun dp(v: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, context.resources.displayMetrics)

    private fun ensureView(): TextView {
        view?.let { return it }
        val density = context.resources.displayMetrics.density
        val tv = TextView(context).apply {
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
            gravity = Gravity.CENTER
            maxLines = 2
            setPadding((16 * density).toInt(), (10 * density).toInt(), (16 * density).toInt(), (10 * density).toInt())
            background = GradientDrawable().apply {
                setColor(0xCC000000.toInt())
                cornerRadius = 18 * density
            }
        }
        view = tv
        return tv
    }

    private fun params(): WindowManager.LayoutParams {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val metrics = context.resources.displayMetrics
        return WindowManager.LayoutParams(
            (metrics.widthPixels - dp(32f)).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = prefs.getInt(KEY_Y, dp(120f).toInt())
        }
    }

    private fun showText(text: String) {
        val tv = ensureView()
        if (!attached) {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val lp = params()
            tv.setOnTouchListener(dragListener(wm, lp))
            try {
                wm.addView(tv, lp)
                attached = true
            } catch (_: Exception) {
                return
            }
        }
        if (shownText != text) {
            tv.text = text
            shownText = text
        }
        tv.visibility = View.VISIBLE
    }

    /** 창은 두고 글만 감춘다 (간주 중 창을 떼었다 붙이지 않는다). */
    private fun hideView() {
        view?.visibility = View.GONE
        shownText = null
    }

    private fun detach() {
        val tv = view ?: return
        if (attached) {
            try {
                (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).removeView(tv)
            } catch (_: Exception) {
            }
            attached = false
        }
        shownText = null
    }

    /** 끌어서 위아래로 옮긴다. 놓은 자리를 기억한다. */
    private fun dragListener(wm: WindowManager, lp: WindowManager.LayoutParams): View.OnTouchListener {
        var startY = 0
        var startTouch = 0f
        return View.OnTouchListener { v, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startY = lp.y
                    startTouch = e.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    lp.y = (startY + (e.rawY - startTouch)).toInt().coerceAtLeast(0)
                    if (attached) wm.updateViewLayout(v, lp)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putInt(KEY_Y, lp.y).apply()
                    true
                }
                else -> false
            }
        }
    }
}
