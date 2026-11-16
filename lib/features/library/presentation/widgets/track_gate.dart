import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../permissions/presentation/bloc/media_access_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/track.dart';

/// 곡 줄이 재생을 시작할 수 있는 상태: 곡을 여는 중이면 [enabled]가 false(눌리지 않음),
/// 미디어 권한이 없어 열 수 없는 기기 파일 곡이면 [unavailable]이 true(흐리게 보이고, 누르면 권한을 묻는다).
class TrackGateState {
  const TrackGateState({
    required this.enabled,
    required this.unavailable,
    required MediaAccessCubit? access,
    required BuildContext context,
  }) : _access = access,
       _context = context;

  final bool enabled;
  final bool unavailable;
  final MediaAccessCubit? _access;
  final BuildContext _context;

  /// [play]를 곡 줄의 onTap으로 쓸 형태로 바꾼다. 권한이 없으면 요청 창(막혔으면 설정)을 먼저 띄우고,
  /// 허용되면 [play]를 실행한다.
  VoidCallback? tap(VoidCallback? play) {
    if (play == null) return null;
    if (!unavailable) return play;
    return () async {
      final level = await _access!.ask();
      if (level == PermissionLevel.granted) return play();
      if (!_context.mounted) return;
      final l10n = _context.l10n;
      final blocked = level == PermissionLevel.blocked;
      // 두 번 거절해 요청 창을 못 띄우면 설정 화면을 갑자기 열지 않고, 안내와 함께 "설정 열기"를 보인다.
      ScaffoldMessenger.of(_context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              blocked ? l10n.permMediaBlockedNotice : l10n.permDeniedNotice,
            ),
            action: blocked
                ? SnackBarAction(
                    label: l10n.permOpenSettings,
                    onPressed: _access.openSettings,
                  )
                : null,
          ),
        );
    };
  }
}

/// 곡 줄을 [TrackGateState]와 함께 그린다 (보관함 · 홈 · 재생목록 등 곡 줄마다 같이 쓴다).
class TrackGate extends StatelessWidget {
  const TrackGate({super.key, required Track this.track, required this.builder})
    : isDeviceFile = null;

  /// 곡 전체가 없고 id만 아는 줄 (재생목록 대표 곡). 기기 파일이면 [isDeviceFile]을 true로 넘긴다.
  const TrackGate.byFlag({
    super.key,
    required bool this.isDeviceFile,
    required this.builder,
  }) : track = null;

  final Track? track;
  final bool? isDeviceFile;
  final Widget Function(BuildContext context, TrackGateState gate) builder;

  @override
  Widget build(BuildContext context) {
    final access = _mediaAccess(context);
    final t = track;
    final allowed =
        access == null ||
        (t != null
            ? access.state.playable(t.id, t.uri)
            : access.state.allowed || !isDeviceFile!);
    final loading = context.read<NowPlayingCubit>().loading;
    return ValueListenableBuilder<bool>(
      valueListenable: loading,
      builder: (context, busy, _) => builder(
        context,
        TrackGateState(
          enabled: !busy,
          unavailable: !allowed,
          access: access,
          context: context,
        ),
      ),
    );
  }
}

/// 앱 전체 미디어 권한 상태 (제공되지 않은 화면이면 null).
MediaAccessCubit? _mediaAccess(BuildContext context) {
  try {
    return context.watch<MediaAccessCubit>();
  } on Object {
    return null;
  }
}
