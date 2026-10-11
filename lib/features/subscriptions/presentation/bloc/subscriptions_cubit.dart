import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../notifications/domain/usecases/notification_usecases.dart';
import '../../domain/entities/subscribed_channel.dart';
import '../../domain/entities/subscription_settings.dart';
import '../../domain/repositories/background_checker.dart';
import '../../domain/usecases/subscription_usecases.dart';

class SubscriptionsState extends Equatable {
  const SubscriptionsState({
    this.loaded = false,
    this.channels = const [],
    this.settings = const SubscriptionSettings(),
  });

  final bool loaded;
  final List<SubscribedChannel> channels;
  final SubscriptionSettings settings;

  /// 새 영상을 확인할 채널(켜 둔 것)이 있는지.
  bool get hasEnabled => channels.any((c) => c.enabled);

  /// 이 채널 주소(또는 채널 id가 든 주소)를 구독 중인지.
  bool isSubscribed(String? channelUrl) {
    if (channelUrl == null || channelUrl.isEmpty) return false;
    return channels.any(
      (c) => c.url == channelUrl || channelUrl.contains(c.id),
    );
  }

  SubscriptionsState copyWith({
    bool? loaded,
    List<SubscribedChannel>? channels,
    SubscriptionSettings? settings,
  }) => SubscriptionsState(
    loaded: loaded ?? this.loaded,
    channels: channels ?? this.channels,
    settings: settings ?? this.settings,
  );

  @override
  List<Object?> get props => [loaded, channels, settings];
}

enum SubscribeResult { added, already, failed }

/// 구독 채널 목록과 새 영상 확인 설정. 바뀔 때마다 저장하고 백그라운드 확인(Android)에 반영한다.
class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  SubscriptionsCubit(
    this._loadChannels,
    this._saveChannels,
    this._loadSettings,
    this._saveSettings,
    this._create,
    this._sync,
    this._requestPermission,
    this._texts,
  ) : super(const SubscriptionsState());

  final LoadSubscribedChannels _loadChannels;
  final SaveSubscribedChannels _saveChannels;
  final LoadSubscriptionSettings _loadSettings;
  final SaveSubscriptionSettings _saveSettings;
  final CreateSubscription _create;
  final SyncBackgroundCheck _sync;
  final RequestNotificationPermission _requestPermission;
  final BackgroundTexts Function() _texts;

  Future<void>? _loading;

  /// 저장된 구독 · 설정을 읽는다 (여러 번 불러도 한 번만 읽는다).
  Future<void> load() => _loading ??= () async {
    final channels = await _loadChannels(const NoParams());
    final settings = await _loadSettings(const NoParams());
    emit(
      SubscriptionsState(loaded: true, channels: channels, settings: settings),
    );
    await _syncBackground();
  }();

  Future<void> _syncBackground() =>
      _sync(SyncBackgroundParams(state.channels, state.settings, _texts()));

  Future<void> _setChannels(List<SubscribedChannel> channels) async {
    emit(state.copyWith(channels: channels));
    await _saveChannels(channels);
    await _syncBackground();
  }

  Future<SubscribeResult> subscribe(SubscribeParams params) async {
    await load();
    if (state.isSubscribed(params.channelUrl)) return SubscribeResult.already;
    final channel = await _create(params);
    if (channel == null) return SubscribeResult.failed;
    if (state.channels.any((c) => c.id == channel.id)) {
      return SubscribeResult.already;
    }
    await _setChannels([...state.channels, channel]);
    return SubscribeResult.added;
  }

  Future<void> unsubscribeByUrl(String channelUrl) => _setChannels([
    for (final c in state.channels)
      if (!(c.url == channelUrl || channelUrl.contains(c.id))) c,
  ]);

  Future<void> unsubscribe(String id) => _setChannels([
    for (final c in state.channels)
      if (c.id != id) c,
  ]);

  Future<void> setEnabled(String id, bool enabled) => _setChannels([
    for (final c in state.channels)
      c.id == id ? c.copyWith(enabled: enabled) : c,
  ]);

  Future<void> setMusicOnly(String id, bool musicOnly) => _setChannels([
    for (final c in state.channels)
      c.id == id ? c.copyWith(musicOnly: musicOnly) : c,
  ]);

  /// 채널별로 여기까지 봤다고 표시한다 (기준 시각을 당긴다).
  Future<void> markSeen(Map<String, DateTime> seenUntil) async {
    final next = markSeenChannels(state.channels, seenUntil);
    if (_same(next, state.channels)) return;
    await _setChannels(next);
  }

  bool _same(List<SubscribedChannel> a, List<SubscribedChannel> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _setSettings(SubscriptionSettings settings) async {
    emit(state.copyWith(settings: settings));
    await _saveSettings(settings);
    await _syncBackground();
  }

  Future<void> setCheckOnLaunch(bool value) =>
      _setSettings(state.settings.copyWith(checkOnLaunch: value));

  /// 백그라운드 확인을 켜면 알림 권한도 요청한다 (새 영상을 알림으로 알리므로).
  Future<void> setBackground(bool value) async {
    if (value) await _requestPermission(const NoParams());
    await _setSettings(state.settings.copyWith(background: value));
  }

  Future<void> setIntervalHours(int hours) =>
      _setSettings(state.settings.copyWith(intervalHours: hours));

  Future<void> setWifiOnly(bool value) =>
      _setSettings(state.settings.copyWith(wifiOnly: value));
}
