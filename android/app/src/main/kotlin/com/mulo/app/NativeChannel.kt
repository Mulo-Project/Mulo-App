package com.mulo.app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

/**
 * Dart와 이어지는 MethodChannel(`music_app/<이름>`) 하나를 쥐는 채널 클래스의 공통 틀.
 * 채널을 만들고, [dispose]에서 호출 처리기를 뗀다. 엔진과 같은 수명이다 ([MuloEngine]).
 * 채널마다 더 정리할 것(스레드 · 콜백)이 있으면 [dispose]를 덮어쓰고 마지막에 `super.dispose()`를 부른다.
 */
abstract class NativeChannel(messenger: BinaryMessenger, private val name: String) {
    protected val channel = MethodChannel(messenger, name)

    private val mainHandler = Handler(Looper.getMainLooper())

    /**
     * 오래 걸리는 일을 [executor]에서 돌리고 결과를 메인 스레드에서 [result]로 돌려준다.
     * 예외가 나면 [errorCode] 오류로 돌려준다 (메시지는 예외 메시지).
     */
    protected fun <T> runAsync(executor: Executor, result: MethodChannel.Result, errorCode: String, block: () -> T) {
        executor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Exception) {
                MuloLog.e(MuloLog.NATIVE, "$name $errorCode 실패: ${e.message}", e)
                mainHandler.post { result.error(errorCode, e.message, null) }
            }
        }
    }

    open fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
