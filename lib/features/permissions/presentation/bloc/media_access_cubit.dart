import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/usecases/permission_usecases.dart';

/// 기기 음악 · 영상 파일을 읽을 수 있는지 (앱 전체). false면 기기 파일(`content://`) 곡은 열 수 없어
/// 곡 줄을 재생 불가로 보인다. 시스템 설정에서 권한을 바꾸고 돌아오면 다시 읽는다.
class MediaAccessCubit extends Cubit<bool> with WidgetsBindingObserver {
  MediaAccessCubit({
    required this._supported,
    required this._level,
    required this._request,
    required this._openSettings,
  }) : super(true) {
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
      if (!isClosed) emit(true);
      return true;
    }
    if (level == PermissionLevel.denied) {
      final next = await _request(AppPermission.audio);
      if (!isClosed) emit(next == PermissionLevel.granted);
      return next == PermissionLevel.granted;
    }
    await _openSettings(const NoParams());
    return false;
  }

  Future<void> refresh() async {
    if (!_supported().contains(AppPermission.audio)) {
      if (!isClosed) emit(true);
      return;
    }
    final level = await _level(AppPermission.audio);
    if (!isClosed) emit(level == PermissionLevel.granted);
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
