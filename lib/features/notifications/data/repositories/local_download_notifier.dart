import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/design/tokens/app_palette.dart';
import '../../domain/repositories/download_notifier.dart';
import '../datasources/notification_texts.dart';

/// 받기 알림(진행 · 결과 · 버튼)은 네이티브가 띄우고 처리한다 (앱이 꺼져 있어도 동작). 여기서는 알림 글과 설정을 넘기고, 본문을 눌러 열라는 요청과 저장한 음원 완료 알림만 맡는다.
class LocalDownloadNotifier implements DownloadNotifier {
  LocalDownloadNotifier({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('music_app/download_notification') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  Future<void>? _init;
  final _opens = StreamController<String>.broadcast();

  @override
  Stream<String> watchOpenRequests() => _opens.stream;

  @override
  Future<String?> takeOpenRequest() async {
    try {
      return await _channel.invokeMethod<String>('takeOpen');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'open') {
      final id = await takeOpenRequest();
      if (id != null) _opens.add(id);
      return;
    }
  }

  Future<void> _ensureInit() => _init ??= () {
    final l10n = systemL10n();
    return _channel.invokeMethod<void>('init', {
      'progressChannel': l10n.notifChannelDownloadProgress,
      'doneChannel': l10n.notifChannelDownloadDone,
      'failedChannel': l10n.notifChannelDownloadFailed,
    });
  }();

  /// 채널 호출이 실패해도(네이티브가 아직 없는 빌드 등) 받기 흐름은 막지 않는다.
  Future<void> _call(String method, [Map<String, Object?>? args]) async {
    try {
      await _ensureInit();
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException {
      // 알림은 부가 기능이다.
    } on MissingPluginException {
      // 알림은 부가 기능이다.
    }
  }

  /// 받기 큐는 네이티브가 쥐고 있어서 글과 설정은 그쪽 채널로 보낸다.
  static const _downloads = MethodChannel('music_app/downloads');

  @override
  Future<void> configureDownloads(Map<String, Object?> config) async {
    final l10n = systemL10n();
    try {
      await _downloads.invokeMethod<void>('configure', {
        'config': jsonEncode({
          ...config,
          'progressChannel': l10n.notifChannelDownloadProgress,
          'doneChannel': l10n.notifChannelDownloadDone,
          'failedChannel': l10n.notifChannelDownloadFailed,
          'color': AppPalette.violet.toARGB32(),
        }),
      });
    } on PlatformException {
      // 알림은 부가 기능이다.
    } on MissingPluginException {
      // 알림은 부가 기능이다.
    }
  }

  @override
  Future<void> setDownloadPreviewing(String? id) async {
    try {
      await _downloads.invokeMethod<void>('setPreviewing', {'id': id});
    } on PlatformException {
      // 알림은 부가 기능이다.
    } on MissingPluginException {
      // 알림은 부가 기능이다.
    }
  }

  @override
  Future<void> showResult({
    required String id,
    required String title,
    required String body,
    required bool failed,
    String? artUri,
  }) => _call('showResult', {
    'id': id,
    'openId': id,
    'title': title,
    'body': body,
    'failed': failed,
    'artUri': artUri,
    'color': AppPalette.violet.toARGB32(),
  });

  @override
  Future<void> clearResults() async {
    if (_init == null) return;
    await _call('clearResults');
  }
}
