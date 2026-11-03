package com.mulo.app

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Dart와 이어지는 MethodChannel(`music_app/<이름>`) 하나를 쥐는 채널 클래스의 공통 틀.
 * 채널을 만들고, [dispose]에서 호출 처리기를 뗀다. 엔진과 같은 수명이다 ([MuloEngine]).
 * 채널마다 더 정리할 것(스레드 · 콜백)이 있으면 [dispose]를 덮어쓰고 마지막에 `super.dispose()`를 부른다.
 */
abstract class NativeChannel(messenger: BinaryMessenger, name: String) {
    protected val channel = MethodChannel(messenger, name)

    open fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
