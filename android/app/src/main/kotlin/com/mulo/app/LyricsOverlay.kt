package com.mulo.app

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * 다른 앱 위에 떠 있는 가사 창. 앱 화면이 보이는 동안에는 숨기고(앱 안에 가사 보기가 있다), 앱을 벗어나면 보인다.
 *
 * 가볍게 돌아가도록: 시간 붙은 가사를 한 번 받아 두고, 재생 위치는 이미 쥐고 있는 ExoPlayer에서 읽는다.
 * 다음 줄 시간에 맞춘 타이머 하나만 예약해 줄이 바뀔 때만 글자를 바꾼다 (주기적인 틱 없음).
 * 멈춤 · 앱이 보임 · 다른 곡 · 가사 없음이면 타이머를 걸지 않고 창을 뗀다.
 *
 * 창을 탭하면 아래에 [숨기기] [끄기]가 나온다 (몇 초 뒤 저절로 사라진다). 끌면 위아래로 옮긴다.
 * 숨기기를 누르면 가사 창이 작은 ♪ 칩으로 줄어든다 (가사 갱신도 멈춘다). 칩을 탭하면 다시 펼쳐진다.
 */
object LyricsOverlay {
    private const val PREFS = "lyrics_overlay"
    private const val KEY_Y = "y"
    private const val MENU_MS = 4000L

    private lateinit var context: Context
    private var initialized = false
    private val main = Handler(Looper.getMainLooper())

    private var trackId = ""
    private var times = LongArray(0)
    private var texts = emptyList<String>()
    private var appVisible = false

    /** 숨기기를 눌러 작은 칩으로 줄어든 상태. 칩을 탭하면 펼친다. */
    private var minimized = false
    private var layout: WindowManager.LayoutParams? = null
    private var chip: TextView? = null
    private var column: LinearLayout? = null
    private var hideLabel = ""
    private var offLabel = ""
    private var accent = 0xFFFFFFFF.toInt()

    /** 사용자가 창에서 끄기를 눌렀을 때 Dart에 알린다 (앱이 살아 있을 때만 설정). */
    var onClosed: (() -> Unit)? = null

    private var view: FrameLayout? = null
    private var current: TextView? = null
    private var upcoming: TextView? = null
    private var menu: LinearLayout? = null
    private var hideButton: TextView? = null
    private var offButton: TextView? = null
    private var attached = false
    private var shownKey: String? = null

    private val tick = Runnable { refresh() }
    private val closeMenu = Runnable { menu?.visibility = View.GONE }

    fun init(appContext: Context) {
        if (initialized) return
        initialized = true
        context = appContext.applicationContext
    }

    fun canDraw(): Boolean = Settings.canDrawOverlays(context)

    /** [id] 곡의 시간 붙은 가사를 받아 둔다. */
    fun show(id: String, newTimes: LongArray, newTexts: List<String>, hide: String, off: String, accentColor: Int) {
        trackId = id
        times = newTimes
        texts = newTexts
        hideLabel = hide
        offLabel = off
        if (accent != accentColor) {
            accent = accentColor
            styleAccent()
        }
        refresh()
    }

    fun hide() {
        minimized = false
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
        val mediaId = exo.currentMediaItem?.mediaId
        val active = times.isNotEmpty() && !appVisible && canDraw() && mediaId == trackId
        if (!active) {
            detach()
            return
        }
        if (minimized) {
            showChip()
            return
        }
        val position = exo.currentPosition
        val index = currentIndex(position)
        val text = if (index >= 0) texts[index] else ""
        val upcomingText = if (index + 1 < texts.size) texts[index + 1] else ""
        if (text.isEmpty()) hideView() else showText(text, upcomingText)
        if (exo.isPlaying) {
            val nextIndex = index + 1
            if (nextIndex < times.size) {
                val speed = exo.playbackParameters.speed.coerceAtLeast(0.1f)
                val wait = ((times[nextIndex] - position) / speed).toLong().coerceAtLeast(30L)
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

    private fun ensureView(): FrameLayout {
        view?.let { return it }
        val density = context.resources.displayMetrics.density
        fun px(v: Int) = (v * density).toInt()
        fun round(color: Int, radiusDp: Float, strokeColor: Int? = null) = GradientDrawable().apply {
            setColor(color)
            cornerRadius = radiusDp * density
            if (strokeColor != null) setStroke(maxOf(1, px(1)), strokeColor)
        }
        val now = TextView(context).apply {
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER
            maxLines = 4
            setLineSpacing(0f, 1.15f)
        }
        val next = TextView(context).apply {
            setTextColor(0x8CFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            gravity = Gravity.CENTER
            maxLines = 2
            setPadding(0, px(8), 0, 0)
        }
        // 끌 수 있음을 알리는 작은 손잡이.
        val handle = View(context).apply {
            background = round(0x38FFFFFF, 2f)
        }
        fun button(onClick: () -> Unit) = TextView(context).apply {
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setPadding(px(18), px(8), px(18), px(8))
            setOnClickListener { onClick() }
        }
        val hideBtn = button { minimize() }
        val offBtn = button { turnOff() }
        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            visibility = View.GONE
            setPadding(0, px(12), 0, 0)
            addView(hideBtn, LinearLayout.LayoutParams(-2, -2).apply { marginEnd = px(8) })
            addView(offBtn, LinearLayout.LayoutParams(-2, -2))
        }
        val body = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(px(20), px(8), px(20), px(14))
            addView(handle, LinearLayout.LayoutParams(px(32), px(4)).apply { bottomMargin = px(8) })
            addView(now, LinearLayout.LayoutParams(-1, -2))
            addView(next, LinearLayout.LayoutParams(-1, -2))
            addView(row, LinearLayout.LayoutParams(-2, -2))
        }
        val note = TextView(context).apply {
            text = "♪"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            gravity = Gravity.CENTER
            visibility = View.GONE
            minWidth = px(44)
            minHeight = px(44)
        }
        val root = FrameLayout(context).apply {
            background = round(0xEB121214.toInt(), 22f, 0x1FFFFFFF)
            addView(body, FrameLayout.LayoutParams(-1, -2))
            addView(note, FrameLayout.LayoutParams(-2, -2))
        }
        column = body
        chip = note
        current = now
        upcoming = next
        menu = row
        hideButton = hideBtn
        offButton = offBtn
        view = root
        styleAccent()
        return root
    }

    /** 앱 테마의 강조색을 칩과 버튼에 입힌다. */
    private fun styleAccent() {
        val density = context.resources.displayMetrics.density
        val onAccent = if (isLight(accent)) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
        chip?.apply {
            setTextColor(onAccent)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(accent)
            }
        }
        hideButton?.apply {
            setTextColor(0xFFFFFFFF.toInt())
            background = GradientDrawable().apply {
                setColor(0x24FFFFFF)
                cornerRadius = 18 * density
            }
        }
        offButton?.apply {
            setTextColor(onAccent)
            background = GradientDrawable().apply {
                setColor(accent)
                cornerRadius = 18 * density
            }
        }
    }

    private fun isLight(color: Int): Boolean {
        val r = (color shr 16) and 0xFF
        val g = (color shr 8) and 0xFF
        val b = color and 0xFF
        return (0.299 * r + 0.587 * g + 0.114 * b) > 150
    }

    /** 창을 탭했다: 옵션을 보이거나 감춘다. 몇 초 뒤엔 저절로 감춘다. */
    private fun toggleMenu() {
        val row = menu ?: return
        main.removeCallbacks(closeMenu)
        if (row.visibility == View.VISIBLE) {
            row.visibility = View.GONE
        } else {
            hideButton?.text = hideLabel
            offButton?.text = offLabel
            row.visibility = View.VISIBLE
            main.postDelayed(closeMenu, MENU_MS)
        }
    }

    /** 숨기기: 가사 창을 작은 칩으로 줄인다. */
    private fun minimize() {
        main.removeCallbacks(closeMenu)
        menu?.visibility = View.GONE
        minimized = true
        refresh()
    }

    private fun expand() {
        minimized = false
        shownKey = null
        refresh()
    }

    /** 칩 모양: 가사 글은 감추고 작은 ♪만 오른쪽 끝에 둔다. */
    private fun showChip() {
        val root = ensureView()
        attachIfNeeded(root)
        column?.visibility = View.GONE
        chip?.visibility = View.VISIBLE
        layout?.let {
            it.width = WindowManager.LayoutParams.WRAP_CONTENT
            it.gravity = Gravity.TOP or Gravity.END
            if (attached) (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).updateViewLayout(root, it)
        }
        root.visibility = View.VISIBLE
        shownKey = null
    }

    /** 끄기: 창을 내리고 설정도 끈다. 앱(Dart)이 꺼져 있어도 다음 실행에 켜져 있지 않도록 저장값도 바꾼다. */
    private fun turnOff() {
        main.removeCallbacks(closeMenu)
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit().putBoolean("flutter.lyrics.overlay", false).apply()
        hide()
        onClosed?.invoke()
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

    private fun attachIfNeeded(root: FrameLayout) {
        if (attached) return
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val lp = params()
        layout = lp
        root.setOnTouchListener(dragListener(wm, lp))
        try {
            wm.addView(root, lp)
            attached = true
        } catch (_: Exception) {
        }
    }

    private fun showText(text: String, next: String) {
        val root = ensureView()
        attachIfNeeded(root)
        if (!attached) return
        if (chip?.visibility == View.VISIBLE) {
            chip?.visibility = View.GONE
            column?.visibility = View.VISIBLE
            layout?.let {
                it.width = (context.resources.displayMetrics.widthPixels - dp(32f)).toInt()
                it.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).updateViewLayout(root, it)
            }
        }
        val key = "$text|$next"
        if (shownKey != key) {
            current?.text = text
            upcoming?.apply {
                this.text = next
                visibility = if (next.isEmpty()) View.GONE else View.VISIBLE
            }
            shownKey = key
        }
        root.visibility = View.VISIBLE
    }

    /** 창은 두고 글만 감춘다 (간주 중 창을 떼었다 붙이지 않는다). */
    private fun hideView() {
        view?.visibility = View.GONE
        shownKey = null
    }

    private fun detach() {
        main.removeCallbacks(closeMenu)
        val root = view ?: return
        if (attached) {
            try {
                (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).removeView(root)
            } catch (_: Exception) {
            }
            attached = false
        }
        menu?.visibility = View.GONE
        shownKey = null
    }

    /** 끌어서 위아래로 옮기고(놓은 자리를 기억), 거의 안 움직이고 놓으면 탭으로 본다. */
    private fun dragListener(wm: WindowManager, lp: WindowManager.LayoutParams): View.OnTouchListener {
        val slop = ViewConfiguration.get(context).scaledTouchSlop
        var startY = 0
        var startTouch = 0f
        var moved = false
        return View.OnTouchListener { v, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startY = lp.y
                    startTouch = e.rawY
                    moved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    if (Math.abs(e.rawY - startTouch) > slop) moved = true
                    if (moved) {
                        lp.y = (startY + (e.rawY - startTouch)).toInt().coerceAtLeast(0)
                        if (attached) wm.updateViewLayout(v, lp)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (moved) {
                        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putInt(KEY_Y, lp.y).apply()
                    } else if (minimized) {
                        expand()
                    } else {
                        toggleMenu()
                    }
                    true
                }
                else -> false
            }
        }
    }
}
