import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/usecases/permission_usecases.dart';

export '../../domain/entities/app_permission.dart';

class PermissionsState extends Equatable {
  const PermissionsState({this.levels = const {}});

  /// 이 기기에서 허용이 필요한 권한과 현재 상태 (불러오기 전 · 필요 없는 OS는 비어 있다).
  final Map<AppPermission, PermissionLevel> levels;

  @override
  List<Object?> get props => [levels];
}

/// 설정의 권한 묶음: 권한별 허용 상태를 보이고, 켜면 요청 창 · 시스템 설정을 연다.
class PermissionsCubit extends Cubit<PermissionsState> {
  PermissionsCubit({
    required this._supported,
    required this._level,
    required this._request,
    required this._openSettings,
  }) : super(const PermissionsState());

  final GetSupportedPermissions _supported;
  final GetPermissionLevel _level;
  final RequestAppPermission _request;
  final OpenPermissionSettings _openSettings;

  /// 처음 열 때, 그리고 시스템 설정에서 앱으로 돌아왔을 때 (그 사이 바꿨을 수 있다).
  Future<void> refresh() async {
    final levels = <AppPermission, PermissionLevel>{};
    for (final p in _supported()) {
      levels[p] = await _level(p);
    }
    if (!isClosed) emit(PermissionsState(levels: levels));
  }

  /// 토글을 눌렀을 때. 요청할 수 있으면 요청 창, 아니면 (이미 허용했거나 막힘) 시스템 설정을 연다.
  Future<void> toggle(AppPermission permission) async {
    final current = state.levels[permission];
    if (current == null) return;
    if (current == PermissionLevel.denied) {
      final next = await _request(permission);
      if (isClosed) return;
      emit(PermissionsState(levels: {...state.levels, permission: next}));
    } else {
      // 허용한 권한은 앱 안에서 거둘 수 없고, 막힌 권한은 요청 창이 뜨지 않는다.
      await _openSettings(const NoParams());
    }
  }
}
