import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../core/design/tokens/app_palette.dart';
import '../../domain/repositories/download_notifier.dart';
import '../datasources/notification_texts.dart';

/// Android 알림창에 받기 진행 · 결과를 띄운다. 알림 · 포그라운드 서비스 · 버튼 수신은 네이티브(Kotlin,
/// `music_app/download_notification`)가 맡고, 여기서는 내용을 넘기고 버튼 누름을 받는다.
/// 버튼은 앱 화면을 열지 않고 살아 있는 엔진으로 바로 전달된다.
/// 받는 중 알림은 [showProgress]의 `foreground`가 true일 때 포그라운드 서비스(dataSync)로 띄워
/// 앱이 뒤로 가거나 닫혀도 받기가 이어지게 한다. 알림의 미리 듣기 버튼은 [watchActions]로 알린다.
class LocalDownloadNotifier implements DownloadNotifier {
  LocalDownloadNotifier({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('music_app/download_notification') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  Future<void>? _init;
  final _actions = StreamController<DownloadNotificationAction>.broadcast();
  final _opens = StreamController<String>.broadcast();

  @override
  Stream<DownloadNotificationAction> watchActions() => _actions.stream;

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
    if (call.method != 'action') return;
    final action = switch (call.arguments) {
      'preview' => DownloadNotificationAction.preview,
      'pausePreview' => DownloadNotificationAction.pausePreview,
      'stopPreview' => DownloadNotificationAction.stopPreview,
      'cancel' => DownloadNotificationAction.cancel,
      _ => null,
    };
    if (action != null) _actions.add(action);
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

  @override
  Future<void> showProgress({
    required String title,
    required String body,
    int? percent,
    bool foreground = true,
    String? subText,
    String? previewLabel,
    String? cancelLabel,
    String? pauseLabel,
    String? stopLabel,
    String? openId,
  }) => _call('showProgress', {
    'title': title,
    'body': body,
    'percent': percent,
    'foreground': foreground,
    'subText': subText,
    'previewLabel': previewLabel,
    'cancelLabel': cancelLabel,
    'pauseLabel': pauseLabel,
    'stopLabel': stopLabel,
    'openId': openId,
    'color': AppPalette.violet.toARGB32(),
  });

  @override
  Future<void> clearProgress() async {
    if (_init == null) return;
    await _call('clearProgress');
  }

  @override
  Future<void> showResult({
    required String id,
    required String title,
    required String body,
    required bool failed,
  }) => _call('showResult', {
    'id': id,
    'openId': id,
    'title': title,
    'body': body,
    'failed': failed,
    'color': AppPalette.violet.toARGB32(),
  });

  @override
  Future<void> clearResults() async {
    if (_init == null) return;
    await _call('clearResults');
  }
}
