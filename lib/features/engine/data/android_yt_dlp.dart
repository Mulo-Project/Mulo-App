import 'dart:io';

import 'package:flutter/services.dart';

/// Android yt-dlp 관리: 네이티브(`music_app/ytdlp`)가 APK에 들어 있는 yt-dlp의 버전을 읽고 올리고 되돌린다.
/// 검색 · 읽기 · 저장은 `NativeYtDlp`가 한다. lite 빌드에는 실제 구현이 없어 [isAvailable]이 false다.
class AndroidYtDlp {
  AndroidYtDlp({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/ytdlp');

  final MethodChannel _channel;

  /// 이 빌드에 로컬 엔진이 들어 있는지 (full).
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// yt-dlp 버전. 실행할 수 없으면 null.
  Future<String?> version() async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('version');
      final v = r?['version'] as String?;
      return v == null || v.isEmpty ? null : v;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// yt-dlp를 최신 안정 버전으로 올리고 새 버전을 돌려준다. 실패하면 예외.
  Future<String?> update() async {
    final r = await _channel.invokeMapMethod<String, Object?>('update');
    return r?['version'] as String?;
  }

  /// 업데이트로 받은 yt-dlp를 지우고 APK에 들어 있는 버전으로 되돌린다. 실패하면 예외.
  Future<void> revert() => _channel.invokeMethod<void>('revert');
}
