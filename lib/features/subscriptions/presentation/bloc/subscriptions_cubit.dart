import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../notifications/domain/usecases/notification_usecases.dart';
import '../../domain/entities/background_status.dart';
import '../../domain/entities/subscribed_channel.dart';
import '../../domain/entities/subscription_settings.dart';
import '../../domain/repositories/background_checker.dart';
import '../../domain/usecases/subscription_usecases.dart';

class SubscriptionsState extends Equatable {
  const SubscriptionsState({
    this.loaded = false,
    this.channels = const [],
    this.settings = const SubscriptionSettings(),
    this.status,
    this.checking = false,
  });

  final bool loaded;
  final List<SubscribedChannel> channels;
  final SubscriptionSettings settings;

  /// 백그라운드 확인 진단 정보 (Android에서만, 아직 모르면 null).
  final BackgroundStatus? status;

  /// "지금 확인"을 돌리는 중인지.
  final bool checking;

  /// 새 영상을 확인할 채널(켜 둔 것)이 있는지.
  bool get hasEnabled => channels.any((c) => c.enabled);

  /// 이 채널 주소(또는 채널 id가 든 주소)를 구독 중인지.
  /// 이 채널 id를 구독 중인지.
  bool isSubscribedId(String id) => channels.any((c) => c.id == id);

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
    BackgroundStatus? status,
    bool? checking,
  }) => SubscriptionsState(
    loaded: loaded ?? this.loaded,
    channels: channels ?? this.channels,
    settings: settings ?? this.settings,
    status: status ?? this.status,
    checking: checking ?? this.checking,
  );

  @override
  List<Object?> get props => [loaded, channels, settings, status, checking];
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
    this._showTest,
    this._checkNow,
    this._getStatus,
  ) : super(const SubscriptionsState());

  final LoadSubscribedChannels _loadChannels;
  final SaveSubscribedChannels _saveChannels;
  final LoadSubscriptionSettings _loadSettings;
  final SaveSubscriptionSettings _saveSettings;
  final CreateSubscription _create;
  final SyncBackgroundCheck _sync;
  final RequestNotificationPermission _requestPermission;
  final BackgroundTexts Function() _texts;
  final ShowTestNewVideosNotification _showTest;
  final CheckNewVideosNow _checkNow;
  final GetBackgroundStatus _getStatus;

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
    if (state.isSubscribed(params.channelUrl) ||
        (params.channelId != null && state.isSubscribedId(params.channelId!))) {
      return SubscribeResult.already;
    }
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

  Future<void> setCategories(String id, Set<String> categories) =>
      _setChannels([
        for (final c in state.channels)
          c.id == id ? c.copyWith(categories: categories) : c,
      ]);

  /// 이 채널의 새 영상을 저장할 폴더를 바꾼다 (비우면 기본 저장 위치).
  Future<void> setSavePath(String id, String path) => _setChannels([
    for (final c in state.channels) c.id == id ? c.copyWith(savePath: path) : c,
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

  /// 진단 정보를 다시 읽는다 (설정 화면을 열 때).
  Future<void> refreshStatus() async {
    final status = await _getStatus(const NoParams());
    if (status != null && !isClosed) emit(state.copyWith(status: status));
  }

  /// 주기를 기다리지 않고 지금 확인한다. 마지막 확인 시각이 바뀔 때까지(최대 1분) 기다린다.
  /// 알림 권한이 없으면 먼저 요청한다.
  Future<void> checkNow() async {
    if (state.checking) return;
    await load();
    emit(state.copyWith(checking: true));
    await _requestPermission(const NoParams());
    // 확인 결과를 최신 채널 · 설정으로 읽도록 한 번 더 반영한다.
    await _syncBackground();
    final before = (await _getStatus(const NoParams()))?.lastRunAt;
    await _checkNow(const NoParams());
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final s = await _getStatus(const NoParams());
      if (s == null) break;
      if (s.lastRunAt != before) break;
    }
    await refreshStatus();
    if (!isClosed) emit(state.copyWith(checking: false));
  }

  /// 알림 모양 확인용 임시 기능: 알림 권한을 요청하고 샘플 새 영상 알림을 띄운다.
  Future<void> showTestNotification() async {
    await load();
    await _requestPermission(const NoParams());
    await _showTest(const NoParams());
  }
}
