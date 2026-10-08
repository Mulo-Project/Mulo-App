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

  /// 대기열 스냅샷을 통째로 바꾼다. 현재 곡이 재생할 준비가 되면 끝난다. 못 열면 던진다.
  /// 현재 곡이 그대로면 재생을 끊지 않는다 (`positionMs`가 없으면 위치도 그대로).
  Future<void> setQueue(Map<String, Object?> snapshot) =>
      _method.invokeMethod('setQueue', snapshot);

  /// 대기열은 그대로 두고 [index]번 곡으로 처음부터 옮긴다.
  Future<void> skipTo(int index) => _method.invokeMethod('skipTo', index);

  /// 네이티브가 지금 쥐고 있는 대기열 스냅샷 (없으면 null).
  Future<Map<Object?, Object?>?> getState() =>
      _method.invokeMapMethod<Object?, Object?>('getState');

  /// 알림을 눌러 앱이 새로 켜졌는지 한 번 알려 주고 비운다.
  Future<bool> takeOpenPlayerRequest() async =>
      await _method.invokeMethod<bool>('takeOpenPlayerRequest') ?? false;

  Future<void> play() => _method.invokeMethod('play');

  Future<void> pause() => _method.invokeMethod('pause');

  Future<void> seek(Duration position) =>
      _method.invokeMethod('seek', position.inMilliseconds);

  /// 대기열 곡별 커버 주소 (곡 id → 주소). 지금 곡이 아닌 곡의 알림 커버로 쓴다.
  Future<void> setQueueArt(Map<String, String> artById) =>
      _method.invokeMethod('setQueueArt', artById);

  /// 알림 · 잠금화면에 보여 줄 내용. null이면 알림을 치운다 (재생은 그대로).
  Future<void> setSession(Map<String, Object?>? session) =>
      _method.invokeMethod('setSession', session);
}
