package com.mulo.app

import android.content.Context
import android.graphics.Outline
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * 다른 앱 위에 떠 있는 가사 창. 앱 안에서도 보이되, 플레이어에서 가사를 보고 있는 동안에는 숨긴다(같은 가사가 겹친다).
 *
 * 가볍게 돌아가도록: 시간 붙은 가사를 한 번 받아 두고, 재생 위치는 이미 쥐고 있는 ExoPlayer에서 읽는다.
 * 다음 줄 시간에 맞춘 타이머 하나만 예약해 줄이 바뀔 때만 글자를 바꾼다 (주기적인 틱 없음).
 * 멈춤 · 가사 보기가 앱에 떠 있음 · 다른 곡 · 가사 없음이면 타이머를 걸지 않고 창을 뗀다.
 *
 * 창을 꾹 누르면 아래에 [숨기기] [끄기]가 나온다 (몇 초 뒤 저절로 사라진다). 끌면 위아래로 옮긴다.
 * 창 맨 아래 손잡이를 아래로 당기면 창이 화면의 [MAX_FRACTION]까지 늘어나, 현재 줄은 가운데에 두고
 * 위에는 지나간 줄, 아래에는 곧 나올 줄이 더 많이 보인다 (고른 높이는 기억한다).
 * 숨기기를 누르면 가사 창이 앱 아이콘 칩으로 줄어든다 (가사 갱신도 멈춘다). 칩은 화면 어디로든 끌어 옮길 수 있고,
 * 탭하면 다시 펼쳐진다.
 */
object LyricsOverlay {
    private const val PREFS = "lyrics_overlay"
    private const val KEY_Y = "y"
    private const val KEY_CHIP_X = "chipX"
    private const val KEY_CHIP_Y = "chipY"
    private const val KEY_EXPAND = "expandPx"
    private const val MENU_MS = 4000L

    /** 이보다 낮게 당기면 늘리지 않은 모양으로 본다 (dp). */
    private const val COMPACT_LIMIT_DP = 150f

    /** 늘어난 창의 가장 큰 높이 (화면 높이의 비율). */
    private const val MAX_FRACTION = 0.8f

    /** 현재 줄 위 · 아래에 미리 만들어 두는 줄 칸 수 (창 높이만큼만 보이고 나머지는 잘린다). */
    private const val MAX_SIDE = 12

    private lateinit var context: Context
    private var initialized = false
    private val main = Handler(Looper.getMainLooper())

    private var trackId = ""
    private var times = LongArray(0)
    private var texts = emptyList<String>()
    private var appVisible = false

    /** 앱 안 플레이어에서 가사를 보고 있는가 (Dart가 알려 준다). 앱이 보일 때만 창을 가린다. */
    private var lyricsViewShown = false

    /** 가사 창의 위 위치 · 칩의 위치(-1이면 오른쪽 끝) · 늘린 창의 높이(0이면 늘리지 않음). 끌어 옮기거나 당기면 기억한다. */
    private var windowY = 0
    private var chipX = -1
    private var chipY = 0
    private var expandedPx = 0

    /** 숨기기를 눌러 작은 칩으로 줄어든 상태. 칩을 탭하면 펼친다. */
    private var minimized = false
    private var layout: WindowManager.LayoutParams? = null
    private var chip: ImageView? = null
    private var column: LinearLayout? = null
    private var hideLabel = ""
    private var offLabel = ""
    private var accent = 0xFFFFFFFF.toInt()

    /** 사용자가 창에서 끄기를 눌렀을 때 Dart에 알린다 (앱이 살아 있을 때만 설정). */
    var onClosed: (() -> Unit)? = null

    private var view: FrameLayout? = null
    private var current: TextView? = null
    private var prevBox: LinearLayout? = null
    private var nextBox: LinearLayout? = null

    /** 현재 줄에 가까운 줄부터 차례로 (prev는 아래에서 위로, next는 위에서 아래로 놓인다). */
    private val prevViews = ArrayList<TextView>()
    private val nextViews = ArrayList<TextView>()

    /** 지금 창에 반영된 모양 (늘림 여부). 바뀔 때만 레이아웃을 다시 정한다. */
    private var appliedExpanded: Boolean? = null

    /** 지금 위 · 아래 줄 칸에 준 세로 여백(px). 창을 더 늘릴수록 줄 사이가 넓어진다. */
    private var appliedGap = -1
    private var menu: LinearLayout? = null
    private var hideButton: TextView? = null
    private var offButton: TextView? = null
    private var attached = false
    private var shownKey: String? = null

    private val tick = Runnable { refresh() }
    private val closeMenu = Runnable { menu?.visibility = View.GONE }

    /** 꾹 눌렀다: 숨기기 · 끄기를 보인다. */
    private var longPressed = false
    private val longPress = Runnable {
        longPressed = true
        view?.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
        showMenu()
    }

    fun init(appContext: Context) {
        if (initialized) return
        initialized = true
        context = appContext.applicationContext
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        windowY = prefs.getInt(KEY_Y, dp(120f).toInt())
        chipX = prefs.getInt(KEY_CHIP_X, -1)
        chipY = prefs.getInt(KEY_CHIP_Y, windowY)
        expandedPx = prefs.getInt(KEY_EXPAND, 0).coerceAtLeast(0)
    }

    fun canDraw(): Boolean = Settings.canDrawOverlays(context)

    /** [id] 곡의 시간 붙은 가사를 받아 둔다. */
    fun show(id: String, newTimes: LongArray, newTexts: List<String>, hide: String, off: String, accentColor: Int) {
        trackId = id
        times = newTimes
        texts = newTexts
        hideLabel = hide
        offLabel = off
        shownKey = null
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

    fun setLyricsViewShown(shown: Boolean) {
        if (lyricsViewShown == shown) return
        lyricsViewShown = shown
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
        val active = times.isNotEmpty() && !(appVisible && lyricsViewShown) && canDraw() && mediaId == trackId
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
        if (text.isEmpty()) hideView() else showLines(index, text)
        if (exo.isPlaying) {
            val nextIndex = index + 1
            if (nextIndex < times.size) {
                val speed = exo.playbackParameters.speed.coerceAtLeast(0.1f)
                val wait = ((times[nextIndex] - position) / speed).toLong().coerceAtLeast(30L)
                main.postDelayed(tick, wait)
            }
        }
    }

    /** [index] 앞의 빈 줄 아닌 줄을 가까운 것부터 최대 [max]개. */
    private fun linesBefore(index: Int, max: Int): List<String> {
        val out = ArrayList<String>(max)
        var i = index - 1
        while (i >= 0 && out.size < max) {
            if (texts[i].isNotEmpty()) out.add(texts[i])
            i--
        }
        return out
    }

    /** [index] 뒤의 빈 줄 아닌 줄을 가까운 것부터 최대 [max]개. */
    private fun linesAfter(index: Int, max: Int): List<String> {
        val out = ArrayList<String>(max)
        var i = index + 1
        while (i < texts.size && out.size < max) {
            if (texts[i].isNotEmpty()) out.add(texts[i])
            i++
        }
        return out
    }

    /** 현재 줄에서 멀수록 흐리게. */
    private fun fadeColor(distance: Int): Int {
        val alpha = (0xB0 - distance * 0x14).coerceAtLeast(0x30)
        return (alpha shl 24) or 0x00FFFFFF
    }

    private fun maxExpandedPx(): Int =
        (context.resources.displayMetrics.heightPixels * MAX_FRACTION).toInt()

    /** 늘린 창의 실제 높이 (화면이 바뀌었어도 최대를 넘지 않는다). 0이면 늘리지 않은 모양. */
    private fun expandedHeight(): Int = if (expandedPx <= 0) 0 else minOf(expandedPx, maxExpandedPx())

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
        fun sideLine() = TextView(context).apply {
            setTextColor(0x8CFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
            maxLines = 2
            ellipsize = android.text.TextUtils.TruncateAt.END
            setPadding(0, px(4), 0, px(4))
            visibility = View.GONE
        }
        // 현재 줄 위: 가까운 줄이 맨 아래에 오도록 아래쪽부터 쌓고, 넘치는 윗부분은 잘린다.
        val before = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.BOTTOM
            visibility = View.GONE
        }
        // 현재 줄 아래: 가까운 줄이 맨 위에 오도록 위쪽부터 쌓고, 넘치는 아랫부분은 잘린다.
        val after = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.TOP
        }
        prevViews.clear()
        nextViews.clear()
        repeat(MAX_SIDE) {
            val up = sideLine()
            prevViews.add(up)
            before.addView(up, 0, LinearLayout.LayoutParams(-1, -2))
            val down = sideLine()
            nextViews.add(down)
            after.addView(down, LinearLayout.LayoutParams(-1, -2))
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
            setPadding(px(20), px(8), px(20), 0)
            addView(handle, LinearLayout.LayoutParams(px(32), px(4)).apply { bottomMargin = px(8) })
            addView(before, LinearLayout.LayoutParams(-1, -2))
            addView(now, LinearLayout.LayoutParams(-1, -2))
            addView(after, LinearLayout.LayoutParams(-1, -2))
            addView(row, LinearLayout.LayoutParams(-2, -2))
            addView(grip(), LinearLayout.LayoutParams(-1, px(26)))
        }
        // 줄어든 모양: 앱 아이콘을 동그랗게 잘라 보인다.
        val note = ImageView(context).apply {
            visibility = View.GONE
            scaleType = ImageView.ScaleType.FIT_CENTER
            // 아이콘이 가장자리에 붙지 않게 안쪽 여백을 두고, 카드와 같은 어두운 바탕 위에 올린다.
            setPadding(px(8), px(8), px(8), px(8))
            background = round(0xEB121214.toInt(), 24f, 0x1FFFFFFF)
            setImageDrawable(context.packageManager.getApplicationIcon(context.packageName))
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setOval(0, 0, view.width, view.height)
                }
            }
            clipToOutline = true
        }
        val root = FrameLayout(context).apply {
            background = round(0xEB121214.toInt(), 22f, 0x1FFFFFFF)
            addView(body, FrameLayout.LayoutParams(-1, -2))
            addView(note, FrameLayout.LayoutParams(px(48), px(48)))
        }
        column = body
        chip = note
        current = now
        prevBox = before
        nextBox = after
        menu = row
        hideButton = hideBtn
        offButton = offBtn
        view = root
        styleAccent()
        return root
    }

    /**
     * 맨 아래 손잡이: 아래로 당기면 창이 늘어나(최대 [MAX_FRACTION]) 지나간 줄과 곧 나올 줄이 더 보인다.
     * 위로 밀어 [COMPACT_LIMIT_DP]보다 낮아지면 원래 모양으로 돌아간다. 놓으면 높이를 기억하고,
     * 손잡이가 터치를 가져가므로 창은 끌리지 않는다.
     */
    private fun grip(): View {
        val density = context.resources.displayMetrics.density
        val bar = View(context).apply {
            background = GradientDrawable().apply {
                setColor(0x38FFFFFF)
                cornerRadius = 2 * density
            }
        }
        var startHeight = 0
        var startTouch = 0f
        return FrameLayout(context).apply {
            addView(bar, FrameLayout.LayoutParams((32 * density).toInt(), (4 * density).toInt(), Gravity.CENTER))
            setOnTouchListener { v, e ->
                when (e.actionMasked) {
                    MotionEvent.ACTION_DOWN -> {
                        v.parent?.requestDisallowInterceptTouchEvent(true)
                        main.removeCallbacks(longPress)
                        startHeight = column?.height ?: 0
                        startTouch = e.rawY
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val h = (startHeight + (e.rawY - startTouch)).toInt().coerceIn(0, maxExpandedPx())
                        val next = if (h < (COMPACT_LIMIT_DP * density).toInt()) 0 else h
                        if (next != expandedPx) {
                            expandedPx = next
                            shownKey = null
                            refresh()
                        }
                    }
                    MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL ->
                        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                            .edit().putInt(KEY_EXPAND, expandedPx).putInt(KEY_Y, windowY).apply()
                }
                true
            }
        }
    }

    /** 앱 테마의 강조색을 칩과 버튼에 입힌다. */
    private fun styleAccent() {
        val density = context.resources.displayMetrics.density
        val onAccent = if (isLight(accent)) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
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

    /** 창을 꾹 눌렀다: 숨기기 · 끄기를 보인다. 몇 초 뒤엔 저절로 감춘다. */
    private fun showMenu() {
        val row = menu ?: return
        main.removeCallbacks(closeMenu)
        hideButton?.text = hideLabel
        offButton?.text = offLabel
        row.visibility = View.VISIBLE
        main.postDelayed(closeMenu, MENU_MS)
    }

    private fun hideMenu() {
        main.removeCallbacks(closeMenu)
        menu?.visibility = View.GONE
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

    /** 칩 모양: 가사 글은 감추고 앱 아이콘 칩만 둔다. 마지막에 놓은 자리(처음엔 오른쪽 끝)에서 어디로든 끌 수 있다. */
    private fun showChip() {
        val root = ensureView()
        attachIfNeeded(root)
        column?.visibility = View.GONE
        chip?.visibility = View.VISIBLE
        layout?.let {
            val size = dp(48f).toInt()
            val maxX = (context.resources.displayMetrics.widthPixels - size).coerceAtLeast(0)
            it.width = WindowManager.LayoutParams.WRAP_CONTENT
            it.gravity = Gravity.TOP or Gravity.START
            it.x = if (chipX < 0) maxX - dp(8f).toInt().coerceAtMost(maxX) else chipX.coerceIn(0, maxX)
            it.y = chipY.coerceAtLeast(0)
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
        val metrics = context.resources.displayMetrics
        return WindowManager.LayoutParams(
            targetWidth(),
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
            y = windowY
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

    private fun showLines(index: Int, text: String) {
        val root = ensureView()
        attachIfNeeded(root)
        if (!attached) return
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        if (chip?.visibility == View.VISIBLE) {
            chip?.visibility = View.GONE
            column?.visibility = View.VISIBLE
            layout?.let {
                it.width = targetWidth()
                it.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                it.x = 0
                it.y = windowY
                wm.updateViewLayout(root, it)
            }
        }
        val height = expandedHeight()
        val expanded = height > 0
        applyMode(root, wm, height)
        val key = "$trackId|$index|$expanded"
        if (shownKey != key) {
            current?.text = text
            if (expanded) {
                fill(prevViews, linesBefore(index, MAX_SIDE))
                fill(nextViews, linesAfter(index, MAX_SIDE))
            } else {
                fill(prevViews, emptyList())
                fill(nextViews, linesAfter(index, 1))
            }
            shownKey = key
        }
        root.visibility = View.VISIBLE
    }

    /**
     * 위 · 아래 줄 사이 간격: 늘리지 않으면 좁게(4dp), 창을 최대로 늘리면 넓게(16dp).
     * 손잡이를 당기는 만큼 줄 사이가 함께 벌어진다.
     */
    private fun applyGap(height: Int) {
        val density = context.resources.displayMetrics.density
        val limit = (COMPACT_LIMIT_DP * density).toInt()
        val room = (maxExpandedPx() - limit).coerceAtLeast(1)
        val fraction = if (height <= 0) 0f else ((height - limit).toFloat() / room).coerceIn(0f, 1f)
        val gap = ((4f + 12f * fraction) * density).toInt()
        if (gap == appliedGap) return
        appliedGap = gap
        for (v in prevViews) v.setPadding(0, gap, 0, gap)
        for (v in nextViews) v.setPadding(0, gap, 0, gap)
    }

    private fun fill(views: List<TextView>, lines: List<String>) {
        for ((k, v) in views.withIndex()) {
            if (k < lines.size) {
                v.text = lines[k]
                v.setTextColor(fadeColor(k))
                v.visibility = View.VISIBLE
            } else {
                v.visibility = View.GONE
            }
        }
    }

    /**
     * 늘림 여부에 맞게 몸통 높이와 위 · 아래 줄 상자를 정한다. 늘린 모양은 몸통 높이를 고정하고
     * 위 · 아래 상자가 남는 높이를 반반 나눠 현재 줄이 가운데에 오게 한다.
     */
    private fun applyMode(root: FrameLayout, wm: WindowManager, height: Int) {
        val expanded = height > 0
        val body = column ?: return
        val lp = body.layoutParams
        val bodyHeight = if (expanded) height else FrameLayout.LayoutParams.WRAP_CONTENT
        if (appliedExpanded != expanded || lp.height != bodyHeight) {
            lp.height = bodyHeight
            body.layoutParams = lp
            prevBox?.apply {
                visibility = if (expanded) View.VISIBLE else View.GONE
                layoutParams = LinearLayout.LayoutParams(-1, 0, 1f)
            }
            nextBox?.layoutParams =
                if (expanded) LinearLayout.LayoutParams(-1, 0, 1f) else LinearLayout.LayoutParams(-1, -2)
            appliedExpanded = expanded
        }
        applyGap(height)
        // 화면이 돌아가 크기가 달라졌으면(가로 · 세로) 너비를 맞추고, 창이 화면 아래로 넘치지 않게 위로 올린다.
        layout?.let {
            if (minimized) return@let
            var changed = false
            val width = targetWidth()
            if (it.width != width) {
                it.width = width
                changed = true
            }
            val bodyHeight = if (expanded) height else (column?.height?.takeIf { h -> h > 0 } ?: dp(110f).toInt())
            val limit = (context.resources.displayMetrics.heightPixels - bodyHeight).coerceAtLeast(0)
            if (it.y > limit) {
                it.y = limit
                changed = true
            }
            if (changed && attached) wm.updateViewLayout(root, it)
        }
    }

    /** 가사 창의 너비: 화면에서 좌우 16dp씩 뺀 만큼, 가로 화면처럼 넓으면 560dp까지만 (가운데에 놓인다). */
    private fun targetWidth(): Int {
        val metrics = context.resources.displayMetrics
        return minOf(metrics.widthPixels - dp(32f).toInt(), dp(560f).toInt()).coerceAtLeast(dp(200f).toInt())
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

    /**
     * 가사 창은 끌면 위아래로, 칩은 어디로든 옮기고(놓은 자리를 기억),
     * 꾹 누르면 숨기기 · 끄기를 보인다. 거의 안 움직이고 놓으면 탭으로 보고, 칩이면 펼친다.
     */
    private fun dragListener(wm: WindowManager, lp: WindowManager.LayoutParams): View.OnTouchListener {
        val slop = ViewConfiguration.get(context).scaledTouchSlop
        var startX = 0
        var startY = 0
        var touchX = 0f
        var touchY = 0f
        var moved = false
        return View.OnTouchListener { v, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startX = lp.x
                    startY = lp.y
                    touchX = e.rawX
                    touchY = e.rawY
                    moved = false
                    longPressed = false
                    if (!minimized) main.postDelayed(longPress, ViewConfiguration.getLongPressTimeout().toLong())
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = e.rawX - touchX
                    val dy = e.rawY - touchY
                    if (!moved && (Math.abs(dx) > slop || Math.abs(dy) > slop)) {
                        moved = true
                        main.removeCallbacks(longPress)
                    }
                    if (moved && !longPressed) {
                        lp.y = (startY + dy).toInt().coerceAtLeast(0)
                        if (minimized) {
                            val maxX = (context.resources.displayMetrics.widthPixels - v.width).coerceAtLeast(0)
                            lp.x = (startX + dx).toInt().coerceIn(0, maxX)
                        }
                        if (attached) wm.updateViewLayout(v, lp)
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    main.removeCallbacks(longPress)
                    val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                    if (moved && !longPressed) {
                        if (minimized) {
                            chipX = lp.x
                            chipY = lp.y
                            prefs.putInt(KEY_CHIP_X, chipX).putInt(KEY_CHIP_Y, chipY)
                        } else {
                            windowY = lp.y
                            prefs.putInt(KEY_Y, windowY)
                        }
                        prefs.apply()
                    } else if (!moved && !longPressed && e.actionMasked == MotionEvent.ACTION_UP) {
                        if (minimized) expand() else if (menu?.visibility == View.VISIBLE) hideMenu()
                    }
                    true
                }
                else -> false
            }
        }
    }
}
