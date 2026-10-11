import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../core/design/tokens/app_palette.dart';
import '../../domain/entities/subscribed_channel.dart';
import '../../domain/entities/subscription_settings.dart';
import '../../domain/repositories/background_checker.dart';

/// Android: 주기 확인 · 알림은 네이티브(Kotlin WorkManager, `music_app/subscriptions`)가 맡는다.
/// 여기서는 구독 채널 · 설정을 넘기고, 알림을 눌러 앱이 열렸는지 받는다.
class NativeBackgroundChecker implements BackgroundChecker {
  NativeBackgroundChecker({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/subscriptions') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  final _opens = StreamController<void>.broadcast();

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'open' && await takeOpenRequest()) _opens.add(null);
  }

  /// 채널 호출이 실패해도(네이티브가 없는 빌드 등) 앱 동작은 막지 않는다.
  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> sync(
    List<SubscribedChannel> channels,
    SubscriptionSettings settings,
    BackgroundTexts texts,
  ) async {
    await _call<void>('sync', {
      'enabled': settings.background,
      'intervalHours': settings.intervalHours,
      'wifiOnly': settings.wifiOnly,
      'channels': [
        for (final c in channels)
          if (c.enabled)
            {
              'id': c.id,
              'name': c.name,
              'baselineMs': c.baselineAt.millisecondsSinceEpoch,
            },
      ],
      'channelName': texts.channelName,
      'title': texts.title,
      'body': texts.body,
      'color': AppPalette.violet.toARGB32(),
    });
  }

  @override
  Future<bool> takeOpenRequest() async =>
      await _call<bool>('takeOpen') ?? false;

  @override
  Stream<void> watchOpenRequests() => _opens.stream;

  @override
  Future<void> clearNotification() => _call<void>('clearNotification');

  @override
  Future<void> showTestNotification() => _call<void>('showTest');
}

/// 백그라운드 확인이 없는 OS: 아무것도 하지 않는다.
class NoBackgroundChecker implements BackgroundChecker {
  const NoBackgroundChecker();

  @override
  Future<void> sync(
    List<SubscribedChannel> channels,
    SubscriptionSettings settings,
    BackgroundTexts texts,
  ) async {}

  @override
  Future<bool> takeOpenRequest() async => false;

  @override
  Stream<void> watchOpenRequests() => const Stream.empty();

  @override
  Future<void> clearNotification() async {}

  @override
  Future<void> showTestNotification() async {}
}
