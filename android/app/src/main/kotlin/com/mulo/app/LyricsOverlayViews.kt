package com.mulo.app

import android.content.Context
import android.graphics.Outline
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewOutlineProvider
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/** [LyricsOverlayViews.build]가 만든 가사 창의 뷰들. 상태 · 터치 처리는 [LyricsOverlay]가 한다. */
internal class LyricsOverlayViewSet(
    val root: FrameLayout,
    /** 줄어들지 않은 모양의 본문 (손잡이 · 가사 · 메뉴). */
    val body: LinearLayout,
    /** 줄어든 모양: 앱 아이콘 칩. */
    val chip: ImageView,
    val current: TextView,
    val upcoming: TextView,
    val scroll: ScrollView,
    val list: LinearLayout,
    val menu: LinearLayout,
    val hideButton: TextView,
    val offButton: TextView,
)

/** 가사 창의 뷰 트리를 만든다 ([LyricsOverlay]에서 분리). 동작은 콜백으로 받는다. */
internal object LyricsOverlayViews {
    /**
     * [scrollTouch]: 늘린 목록의 터치, [onHandleTouch]: 맨 위 손잡이 터치(창 끌기),
     * [grip]: 맨 아래 손잡이, [onHide]/[onOff]: 메뉴의 숨기기 · 끄기 버튼.
     */
    fun build(
        context: Context,
        scrollTouch: View.OnTouchListener,
        onHandleTouch: (MotionEvent) -> Boolean,
        grip: View,
        onHide: () -> Unit,
        onOff: () -> Unit,
    ): LyricsOverlayViewSet {
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
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
            setPadding(0, px(8), 0, px(4))
            visibility = View.GONE
        }
        // 늘린 모양: 가사 전체를 넘겨 볼 수 있는 목록. 터치는 스크롤이 쓰므로 꾹 누르기만 따로 본다.
        val rows = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        val scrollView = ScrollView(context).apply {
            isVerticalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
            visibility = View.GONE
            addView(rows, FrameLayout.LayoutParams(-1, -2))
            setOnTouchListener(scrollTouch)
        }
        // 맨 위 손잡이: 창을 끌어 옮기는 곳 (늘린 모양에서는 가사 목록이 터치를 써서 여기로 옮긴다).
        val handleBar = View(context).apply { background = round(0x38FFFFFF, 2f) }
        val handle = FrameLayout(context).apply {
            addView(handleBar, FrameLayout.LayoutParams(px(32), px(4), Gravity.CENTER))
            setOnTouchListener { _, e -> onHandleTouch(e) }
        }
        fun button(onClick: () -> Unit) = TextView(context).apply {
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setPadding(px(18), px(8), px(18), px(8))
            setOnClickListener { onClick() }
        }
        val hideBtn = button(onHide)
        val offBtn = button(onOff)
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
            setPadding(px(20), 0, px(20), 0)
            addView(handle, LinearLayout.LayoutParams(-1, px(22)))
            addView(scrollView, LinearLayout.LayoutParams(-1, 0, 1f))
            addView(now, LinearLayout.LayoutParams(-1, -2))
            addView(next, LinearLayout.LayoutParams(-1, -2))
            addView(row, LinearLayout.LayoutParams(-2, -2))
            addView(grip, LinearLayout.LayoutParams(-1, px(26)))
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
        return LyricsOverlayViewSet(root, body, note, now, next, scrollView, rows, row, hideBtn, offBtn)
    }
}
