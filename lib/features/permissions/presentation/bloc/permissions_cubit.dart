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
/// 요청 결과가 이 시간보다 빨리 막힘으로 돌아오면 시스템 요청 창이 뜨지 않은 것으로 본다.
const _noDialogMs = 400;

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
  /// 요청 창을 띄웠으면 그 결과를 돌려준다 (허용이 아니면 화면이 안내를 보인다). 설정을 열었으면 null.
  Future<PermissionLevel?> toggle(AppPermission permission) async {
    final current = state.levels[permission];
    if (current == null) return null;
    if (current == PermissionLevel.denied) {
      // 두 번 거절한 권한은 앱을 다시 켜면 상태가 "아직 안 물음"과 같아 보여서 요청 창이 뜨지 않고 바로 막힘으로 돌아온다.
      // 창이 뜰 틈도 없이(아주 빨리) 막힘이 돌아오면 사용자는 아무 변화도 못 봤으니 바로 시스템 설정을 연다.
      final watch = Stopwatch()..start();
      final next = await _request(permission);
      if (isClosed) return next;
      emit(PermissionsState(levels: {...state.levels, permission: next}));
      if (next == PermissionLevel.blocked &&
          watch.elapsedMilliseconds < _noDialogMs) {
        await _openSettings(const NoParams());
        return null;
      }
      return next;
    } else {
      // 허용한 권한은 앱 안에서 거둘 수 없고, 막힌 권한은 요청 창이 뜨지 않는다.
      await _openSettings(const NoParams());
      return null;
    }
  }
}
