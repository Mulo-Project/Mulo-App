import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  }) : _access = access;

  final bool enabled;
  final bool unavailable;
  final MediaAccessCubit? _access;

  /// [play]를 곡 줄의 onTap으로 쓸 형태로 바꾼다. 권한이 없으면 요청 창(막혔으면 설정)을 먼저 띄우고,
  /// 허용되면 [play]를 실행한다.
  VoidCallback? tap(VoidCallback? play) {
    if (play == null) return null;
    if (!unavailable) return play;
    return () async {
      if (await _access!.ask()) play();
    };
  }
}

/// 곡 줄을 [TrackGateState]와 함께 그린다 (보관함 · 홈 · 재생목록 등 곡 줄마다 같이 쓴다).
class TrackGate extends StatelessWidget {
  const TrackGate({super.key, required this.track, required this.builder});

  final Track track;
  final Widget Function(BuildContext context, TrackGateState gate) builder;

  @override
  Widget build(BuildContext context) {
    final access = _mediaAccess(context);
    final allowed =
        access == null || access.state || !track.uri.startsWith('content://');
    final loading = context.read<NowPlayingCubit>().loading;
    return ValueListenableBuilder<bool>(
      valueListenable: loading,
      builder: (context, busy, _) => builder(
        context,
        TrackGateState(enabled: !busy, unavailable: !allowed, access: access),
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
