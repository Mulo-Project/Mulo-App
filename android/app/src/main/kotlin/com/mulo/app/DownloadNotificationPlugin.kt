package com.mulo.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 받기 알림 채널(`music_app/download_notification`). Dart가 알림 내용을 넘기면 네이티브가 띄우고,
 * 알림 버튼은 [DownloadActionReceiver]가 받아 `action`으로 되돌려 준다.
 * 화면(Activity)이 아니라 엔진에 묶여 있어서, 화면이 닫혀도 엔진이 살아 있는 동안 계속 동작한다.
 */
class DownloadNotificationPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, NAME).also { it.setMethodCallHandler(this) }
        active = channel
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        if (active === channel) active = null
        channel = null
        context = null
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: return result.error("detached", "엔진에서 떨어짐", null)
        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
        try {
            when (call.method) {
                "init" -> DownloadNotifications.createChannels(ctx, args)
                "showProgress" -> {
                    DownloadNotifications.lastProgress = args
                    // 서비스가 알림을 붙들고, 이미 떠 있으면 같은 id로 갱신한다.
                    if (args["foreground"] != true) DownloadForegroundService.stop(ctx)
                    else DownloadForegroundService.start(ctx)
                    DownloadNotifications.showProgress(ctx, args)
                }
                "clearProgress" -> {
                    DownloadNotifications.lastProgress = null
                    DownloadForegroundService.stop(ctx)
                    DownloadNotifications.clearProgress(ctx)
                }
                "showResult" -> DownloadNotifications.showResult(ctx, args)
                "clearResults" -> DownloadNotifications.clearResults(ctx)
                else -> return result.notImplemented()
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }

    companion object {
        const val NAME = "music_app/download_notification"
        private val main = Handler(Looper.getMainLooper())

        @Volatile
        private var active: MethodChannel? = null

        /** 알림 버튼 누름을 Dart로 보낸다. 엔진이 없으면(앱 프로세스가 없었던 경우) 할 일이 없다. */
        fun dispatch(action: String) {
            main.post { active?.invokeMethod("action", action) }
        }
    }
}
