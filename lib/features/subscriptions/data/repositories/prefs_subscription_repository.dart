import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/subscribed_channel.dart';
import '../../domain/entities/subscription_settings.dart';
import '../../domain/repositories/subscription_repository.dart';

/// 구독 채널(JSON 목록)과 확인 설정을 shared_preferences에 저장한다. 구독은 몇십 개 안팎이라
/// DB 대신 받기 대기열처럼 한 덩어리로 둔다.
class PrefsSubscriptionRepository implements SubscriptionRepository {
  static const _channelsKey = 'subscriptions.channels';
  static const _launchKey = 'subscriptions.checkOnLaunch';
  static const _backgroundKey = 'subscriptions.background';
  static const _intervalKey = 'subscriptions.intervalHours';
  static const _wifiKey = 'subscriptions.wifiOnly';

  @override
  Future<List<SubscribedChannel>> loadChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_channelsKey);
    if (raw == null) return const [];
    try {
      return [
        for (final j in (jsonDecode(raw) as List).whereType<Map>())
          ?_fromJson(j.cast<String, Object?>()),
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> saveChannels(List<SubscribedChannel> channels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _channelsKey,
      jsonEncode([for (final c in channels) _toJson(c)]),
    );
  }

  @override
  Future<SubscriptionSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final interval = prefs.getInt(_intervalKey) ?? 3;
    return SubscriptionSettings(
      checkOnLaunch: prefs.getBool(_launchKey) ?? true,
      background: prefs.getBool(_backgroundKey) ?? false,
      intervalHours: SubscriptionSettings.intervals.contains(interval)
          ? interval
          : 3,
      wifiOnly: prefs.getBool(_wifiKey) ?? true,
    );
  }

  @override
  Future<void> saveSettings(SubscriptionSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_launchKey, s.checkOnLaunch);
    await prefs.setBool(_backgroundKey, s.background);
    await prefs.setInt(_intervalKey, s.intervalHours);
    await prefs.setBool(_wifiKey, s.wifiOnly);
  }

  static Map<String, Object?> _toJson(SubscribedChannel c) => {
    'id': c.id,
    'name': c.name,
    'url': c.url,
    'thumbnail': c.thumbnailUrl,
    'enabled': c.enabled,
    'categories': c.categories.toList(),
    'baselineAt': c.baselineAt.toUtc().toIso8601String(),
  };

  static SubscribedChannel? _fromJson(Map<String, Object?> j) {
    final id = j['id'];
    final baseline = DateTime.tryParse('${j['baselineAt']}');
    if (id is! String || baseline == null) return null;
    return SubscribedChannel(
      id: id,
      name: j['name'] as String? ?? '',
      url: j['url'] as String? ?? '',
      thumbnailUrl: j['thumbnail'] as String?,
      enabled: j['enabled'] as bool? ?? true,
      categories: {
        ...(j['categories'] as List? ?? const []).whereType<String>(),
        // 예전 "음악만" 값.
        if (j['musicOnly'] == true) 'Music',
      },
      baselineAt: baseline.toUtc(),
    );
  }
}
