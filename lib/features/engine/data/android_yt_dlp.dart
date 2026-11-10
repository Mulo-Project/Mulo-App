import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../search/data/engine/local_engine.dart' show ytDlpTimeout;

/// Android 로컬 엔진: 네이티브(`music_app/ytdlp`)가 APK에 들어 있는 yt-dlp를 실행한다.
/// lite 빌드에는 실제 구현이 없어 [isAvailable]이 false다.
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

  /// 데스크톱 `Process.run`과 같은 모양으로 실행한다 (`LocalEngine`이 같이 쓴다).
  /// 마지막 인자는 주소(또는 `ytsearch…:검색어`), 앞은 옵션이다.
  /// 실행할 수 없는 빌드면 [ProcessException]을 던진다.
  ///
  /// [timeout]은 이 실행이 끝나기를 기다리는 시간(기본은 검색 · 정보 읽기용으로 짧다).
  /// [background]가 true면 다른 yt-dlp 실행 줄과 따로 돌려, 오래 걸려도 검색 · 주소 읽기를 막지 않는다
  /// (영상 파일 받기용).
  Future<({int exitCode, String stdout, String stderr})> run(
    String executable,
    List<String> args, {
    Duration timeout = ytDlpTimeout,
    bool background = false,
  }) async {
    if (args.length == 1 && args.first == '--version') {
      final v = await version();
      if (v == null) throw ProcessException(executable, args);
      return (exitCode: 0, stdout: v, stderr: '');
    }
    if (args.isEmpty) throw ProcessException(executable, args);
    final id = 'run${_seq++}';
    try {
      final r = await _channel
          .invokeMapMethod<String, Object?>('run', {
            'url': args.last,
            'options': args.sublist(0, args.length - 1),
            'id': id,
            'background': background,
          })
          .timeout(timeout);
      return (
        exitCode: (r?['exitCode'] as num?)?.toInt() ?? 1,
        stdout: r?['stdout'] as String? ?? '',
        stderr: r?['stderr'] as String? ?? '',
      );
    } on TimeoutException {
      // 멈춘 yt-dlp가 실행 줄을 계속 막지 않게 끊고, 위(LocalEngine)가 시간 초과로 알린다.
      unawaited(
        _channel
            .invokeMethod<bool>('cancel', {'id': id})
            .catchError((_) => null),
      );
      rethrow;
    } on MissingPluginException {
      throw ProcessException(executable, args);
    } on PlatformException catch (e) {
      return (exitCode: 1, stdout: '', stderr: e.message ?? '');
    }
  }

  int _seq = 0;
}
