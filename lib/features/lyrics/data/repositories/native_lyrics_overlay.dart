import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/lyrics_overlay.dart';

/// Android 네이티브(`music_app/lyrics_overlay`)가 그리는 떠 있는 가사 창.
class NativeLyricsOverlay implements LyricsOverlay {
  NativeLyricsOverlay({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/lyrics_overlay') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'closed') _closed.add(null);
    });
  }

  final MethodChannel _channel;
  final _closed = StreamController<void>.broadcast();

  @override
  Stream<void> watchClosed() => _closed.stream;

  @override
  Future<bool> canDraw() async =>
      await _channel.invokeMethod<bool>('canDraw') ?? false;

  @override
  Future<void> openPermissionSettings() =>
      _channel.invokeMethod('openPermissionSettings');

  @override
  Future<void> show(
    String trackId,
    List<LyricLine> lines, {
    required String hideLabel,
    required String offLabel,
    required int accent,
    String emptyLabel = '',
  }) => _channel.invokeMethod('show', {
    'emptyLabel': emptyLabel,
    'hideLabel': hideLabel,
    'offLabel': offLabel,
    'accent': accent,
    'trackId': trackId,
    'times': [for (final l in lines) l.time.inMilliseconds],
    'texts': [for (final l in lines) l.text],
  });

  @override
  Future<void> setLyricsViewShown(bool shown) =>
      _channel.invokeMethod('setLyricsViewShown', shown);

  @override
  Future<void> hide() => _channel.invokeMethod('hide');
}

/// 떠 있는 창이 없는 OS (Windows · Linux · macOS)용: 아무것도 하지 않는다.
class NoLyricsOverlay implements LyricsOverlay {
  @override
  Stream<void> watchClosed() => const Stream.empty();

  @override
  Future<bool> canDraw() async => false;

  @override
  Future<void> openPermissionSettings() async {}

  @override
  Future<void> show(
    String trackId,
    List<LyricLine> lines, {
    required String hideLabel,
    required String offLabel,
    required int accent,
    String emptyLabel = '',
  }) async {}

  @override
  Future<void> setLyricsViewShown(bool shown) async {}

  @override
  Future<void> hide() async {}
}
