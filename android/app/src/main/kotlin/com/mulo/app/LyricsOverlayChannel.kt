package com.mulo.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger

/** 떠 있는 가사 창 ([LyricsOverlay]): 권한 확인 · 가사 보내기 · 지우기. */
class LyricsOverlayChannel(private val context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME) {

    init {
        LyricsOverlay.init(context)
        LyricsOverlay.onClosed = { channel.invokeMethod("closed", null) }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "canDraw" -> result.success(LyricsOverlay.canDraw())
                "openPermissionSettings" -> {
                    context.startActivity(
                        Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${context.packageName}"))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                "show" -> {
                    val map = call.arguments as? Map<*, *>
                    android.util.Log.d("MuloLyrics", "show trackId=${map?.get("trackId")} lines=${(map?.get("times") as? List<*>)?.size}")
                    val id = map?.get("trackId") as? String
                    val times = (map?.get("times") as? List<*>)?.map { (it as Number).toLong() }
                    val texts = (map?.get("texts") as? List<*>)?.map { it as? String ?: "" }
                    if (id == null || times == null || texts == null || times.size != texts.size) {
                        result.error("bad_args", "trackId · times · texts required", null)
                    } else {
                        LyricsOverlay.show(
                            id,
                            times.toLongArray(),
                            texts,
                            map.get("hideLabel") as? String ?: "",
                            map.get("offLabel") as? String ?: "",
                            (map.get("accent") as? Number)?.toInt() ?: 0xFFFFFFFF.toInt(),
                            map.get("emptyLabel") as? String ?: "",
                        )
                        result.success(null)
                    }
                }
                "setLyricsViewShown" -> {
                    LyricsOverlay.setLyricsViewShown(call.arguments as? Boolean ?: false)
                    result.success(null)
                }
                "hide" -> {
                    LyricsOverlay.hide()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispose() {
        super.dispose()
        LyricsOverlay.onClosed = null
    }

    companion object {
        const val NAME = "music_app/lyrics_overlay"
    }
}
