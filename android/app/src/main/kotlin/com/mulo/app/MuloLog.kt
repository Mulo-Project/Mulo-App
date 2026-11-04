package com.mulo.app

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log

/**
 * 네이티브 오류를 잡기 위한 debug 전용 로그 (`adb logcat -s MuloNative MuloPlayback`).
 * 릴리스 빌드에서는 아무것도 남기지 않는다 (경로 · 곡 정보가 로그에 새지 않게).
 * 앱 프로세스가 뜰 때 [init]을 한 번 불러 debug 빌드인지 읽는다.
 */
object MuloLog {
    const val NATIVE = "MuloNative"
    const val PLAYBACK = "MuloPlayback"

    @Volatile
    private var debuggable = false

    fun init(context: Context) {
        debuggable = (context.applicationContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    fun d(tag: String, message: String) {
        if (debuggable) Log.d(tag, message)
    }

    fun e(tag: String, message: String, error: Throwable? = null) {
        if (debuggable) Log.e(tag, message, error)
    }
}
