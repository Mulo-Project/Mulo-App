import 'dart:async';

import 'package:flutter/services.dart';

/// 네이티브 재생 서비스(Android: Media3 `MediaSessionService`)와 주고받는 통로.
/// 재생 엔진 · 미디어 세션 · 알림은 모두 네이티브가 쥐고, Dart는 명령을 보내고 이벤트를 받는다.
/// 약속(메서드 · 이벤트 모양)은 docs/native-playback.md. Windows 등은 같은 약속으로 따로 구현한다.
class NativePlaybackChannel {
  NativePlaybackChannel({MethodChannel? method, EventChannel? events})
    : _method = method ?? const MethodChannel('music_app/playback'),
      _events = events ?? const EventChannel('music_app/playback/events');

  final MethodChannel _method;
  final EventChannel _events;

  late final Stream<Map<Object?, Object?>> _stream = _events
      .receiveBroadcastStream()
      .where((e) => e is Map)
      .cast<Map<Object?, Object?>>()
      .asBroadcastStream();

  /// 네이티브가 보낸 이벤트 (`type` 키로 구분).
  Stream<Map<Object?, Object?>> get events => _stream;

  /// [uri]를 불러와 재생할 준비가 되면 끝난다. 못 열면 던진다.
  Future<void> load(String uri) => _method.invokeMethod('load', uri);

  Future<void> play() => _method.invokeMethod('play');

  Future<void> pause() => _method.invokeMethod('pause');

  Future<void> seek(Duration position) =>
      _method.invokeMethod('seek', position.inMilliseconds);

  /// 알림 · 잠금화면에 보여 줄 내용. null이면 알림을 치운다 (재생은 그대로).
  Future<void> setSession(Map<String, Object?>? session) =>
      _method.invokeMethod('setSession', session);
}
