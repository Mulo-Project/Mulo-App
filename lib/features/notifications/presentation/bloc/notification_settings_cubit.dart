import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/usecases/notification_usecases.dart';

export '../../domain/entities/notification_settings.dart';

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.settings = const NotificationSettings(),
    this.loaded = false,
    this.permissionGranted = true,
  });

  final NotificationSettings settings;

  /// 저장된 설정을 읽기 전에는 알림을 띄우지 않는다 (숨김 설정이 아직 반영되지 않았으므로).
  final bool loaded;

  /// 시스템 알림 권한. false면 설정에서 안내 줄을 보인다.
  final bool permissionGranted;

  NotificationSettingsState copyWith({
    NotificationSettings? settings,
    bool? loaded,
    bool? permissionGranted,
  }) => NotificationSettingsState(
    settings: settings ?? this.settings,
    loaded: loaded ?? this.loaded,
    permissionGranted: permissionGranted ?? this.permissionGranted,
  );

  @override
  List<Object?> get props => [settings, loaded, permissionGranted];
}

/// 알림 설정 (받기 진행 · 결과, 재생 알림, 곡 정보 숨기기) + 시스템 알림 권한.
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required this._load,
    required this._save,
    required this._isGranted,
    required this._request,
    required this._openSystemSettings,
  }) : super(const NotificationSettingsState());

  final LoadNotificationSettings _load;
  final SaveNotificationSettings _save;
  final IsNotificationPermissionGranted _isGranted;
  final RequestNotificationPermission _request;
  final OpenNotificationSystemSettings _openSystemSettings;

  Future<void> load() async {
    final settings = await _load(const NoParams());
    final granted = await _isGranted(const NoParams());
    if (isClosed) return;
    emit(
      state.copyWith(
        settings: settings,
        loaded: true,
        permissionGranted: granted,
      ),
    );
  }

  /// 앱이 앞으로 돌아왔을 때 (시스템 설정에서 바꿨을 수 있다).
  Future<void> refreshPermission() async {
    final granted = await _isGranted(const NoParams());
    if (!isClosed && granted != state.permissionGranted) {
      emit(state.copyWith(permissionGranted: granted));
    }
  }

  Future<void> openSystemSettings() => _openSystemSettings(const NoParams());

  Future<void> _update(
    NotificationSettings next, {
    bool needsPermission = false,
  }) async {
    emit(state.copyWith(settings: next));
    await _save(next);
    // 알림을 켜는 순간 권한이 없으면 묻는다.
    if (needsPermission && !state.permissionGranted) {
      final granted = await _request(const NoParams());
      if (!isClosed) emit(state.copyWith(permissionGranted: granted));
    }
  }

  Future<void> setDownloadProgress(bool on) => _update(
    state.settings.copyWith(downloadProgress: on),
    needsPermission: on,
  );

  Future<void> setDownloadResult(bool on) =>
      _update(state.settings.copyWith(downloadResult: on), needsPermission: on);

  Future<void> setPlayback(bool on) =>
      _update(state.settings.copyWith(playback: on), needsPermission: on);

  Future<void> setBackgroundDownload(bool on) => _update(
    state.settings.copyWith(backgroundDownload: on),
    needsPermission: on,
  );

  Future<void> setHideSongInfo(bool on) =>
      _update(state.settings.copyWith(hideSongInfo: on));
}
