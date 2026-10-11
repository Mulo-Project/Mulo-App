import 'package:equatable/equatable.dart';

/// 새 영상 확인 설정.
class SubscriptionSettings extends Equatable {
  const SubscriptionSettings({
    this.checkOnLaunch = true,
    this.background = false,
    this.intervalHours = 3,
    this.wifiOnly = true,
  });

  /// 고를 수 있는 확인 주기(시간).
  static const intervals = [1, 3, 6];

  /// 앱을 켤 때 구독 채널의 새 영상을 확인한다.
  final bool checkOnLaunch;

  /// 앱이 꺼져 있어도 주기적으로 확인하고 새 영상이 있으면 알린다 (Android).
  final bool background;

  /// 백그라운드 확인 주기(시간): 1 · 3 · 6.
  final int intervalHours;

  /// 백그라운드 확인은 와이파이(데이터 요금 없는 연결)에서만 한다.
  final bool wifiOnly;

  SubscriptionSettings copyWith({
    bool? checkOnLaunch,
    bool? background,
    int? intervalHours,
    bool? wifiOnly,
  }) => SubscriptionSettings(
    checkOnLaunch: checkOnLaunch ?? this.checkOnLaunch,
    background: background ?? this.background,
    intervalHours: intervalHours ?? this.intervalHours,
    wifiOnly: wifiOnly ?? this.wifiOnly,
  );

  @override
  List<Object?> get props => [
    checkOnLaunch,
    background,
    intervalHours,
    wifiOnly,
  ];
}
