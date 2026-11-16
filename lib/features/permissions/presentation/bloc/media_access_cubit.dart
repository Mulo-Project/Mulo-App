import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/usecases/permission_usecases.dart';

class MediaAccessState extends Equatable {
  const MediaAccessState({this.allowed = true, this.failed = const {}});

  /// 미디어 권한이 허용돼 있는가.
  final bool allowed;

  /// 이번 실행에서 열기에 실패한 곡 id (파일이 없거나 이전 설치가 만든 파일 등). 앱을 다시 켜면 비운다.
  final Set<String> failed;

  /// 이 곡을 재생할 수 있는가: 기기 파일(`content://`)은 권한이 있어야 하고, 열기에 실패한 곡은 뺀다.
  bool playable(String id, String uri) =>
      !failed.contains(id) && (allowed || !uri.startsWith('content://'));

  @override
  List<Object?> get props => [allowed, failed];
}

/// 기기 음악 · 영상 파일을 읽을 수 있는지 (앱 전체). false면 기기 파일(`content://`) 곡은 열 수 없어
/// 곡 줄을 재생 불가로 보인다. 시스템 설정에서 권한을 바꾸고 돌아오면 다시 읽는다.
class MediaAccessCubit extends Cubit<MediaAccessState>
    with WidgetsBindingObserver {
  MediaAccessCubit({
    required this._supported,
    required this._level,
    required this._request,
    required this._openSettings,
  }) : super(const MediaAccessState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final GetSupportedPermissions _supported;
  final GetPermissionLevel _level;
  final RequestAppPermission _request;
  final OpenPermissionSettings _openSettings;

  /// 곡을 열려는데 권한이 없을 때: 요청 창을 띄울 수 있으면 띄우고, 막혔으면 시스템 설정을 연다.
  /// 허용으로 바뀌면 true.
  Future<bool> ask() async {
    final level = await _level(AppPermission.audio);
    if (level == PermissionLevel.granted) {
      _setAllowed(true);
      return true;
    }
    if (level == PermissionLevel.denied) {
      final watch = Stopwatch()..start();
      final next = await _request(AppPermission.audio);
      _setAllowed(next == PermissionLevel.granted);
      // 요청 창이 뜨지 않고 바로 막힘으로 돌아오면(두 번 거절한 뒤) 시스템 설정을 연다.
      if (next == PermissionLevel.blocked && watch.elapsedMilliseconds < 400) {
        await _openSettings(const NoParams());
      }
      return next == PermissionLevel.granted;
    }
    await _openSettings(const NoParams());
    return false;
  }

  Future<void> refresh() async {
    if (!_supported().contains(AppPermission.audio)) {
      _setAllowed(true);
      return;
    }
    final level = await _level(AppPermission.audio);
    _setAllowed(level == PermissionLevel.granted);
  }

  /// 권한이 허용으로 바뀌면 열기 실패 기록도 지운다 (이전에 막혔던 곡이 이제 열릴 수 있다).
  void _setAllowed(bool allowed) {
    if (isClosed) return;
    emit(
      MediaAccessState(
        allowed: allowed,
        failed: allowed && !state.allowed ? const {} : state.failed,
      ),
    );
  }

  /// 곡을 열다 실패했다: 곡 줄을 흐리게 하고 대기열에서 뺀다.
  void markFailed(String id) {
    if (isClosed || state.failed.contains(id)) return;
    emit(MediaAccessState(allowed: state.allowed, failed: {...state.failed, id}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}
