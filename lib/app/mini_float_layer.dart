import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/design/design.dart';
import '../core/l10n/l10n.dart';
import '../features/covers/presentation/bloc/cover_cubit.dart';
import '../features/player/presentation/bloc/now_playing_cubit.dart';
import '../features/search/presentation/bloc/preview_cubit.dart';

/// 플로팅 버튼이 놓일 수 있는 영역 계산. 위치는 버튼의 왼쪽 위 모서리 기준이다.
class MiniFloatGeometry {
  const MiniFloatGeometry({required this.area, required this.safe});

  /// 본문 전체에서 버튼이 통째로 들어가는 영역 (끌고 있는 동안 손가락을 따라가는 범위).
  final Rect area;

  /// 놓은 뒤 자리 잡는 영역. 위쪽 상태 표시줄 · 아래쪽 하단 바 · 받기 줄(또는 받기 버튼) 위를 피한다.
  final Rect safe;

  static Offset clampTo(Rect r, Offset p) => Offset(
    p.dx.clamp(r.left, r.right < r.left ? r.left : r.right),
    p.dy.clamp(r.top, r.bottom < r.top ? r.top : r.bottom),
  );

  /// 놓은 자리에서 가까운 좌우 가장자리로 붙인다.
  Offset snap(Offset p) {
    final c = clampTo(safe, p);
    final mid = (safe.left + safe.right) / 2;
    return Offset(c.dx < mid ? safe.left : safe.right, c.dy);
  }
}

/// 본문 위에 얹는 미니 플레이어 플로팅 버튼. 부모 [Stack]이 본문 전체 크기여야 한다.
/// 처음 나타날 때 통통 튀며 커지고, 놓으면 가장자리로 튕기듯 붙는다.
class MiniFloatLayer extends StatelessWidget {
  const MiniFloatLayer({
    super.key,
    required this.position,
    required this.moving,
    required this.geometry,
    required this.gripping,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onExpand,
  });

  final ValueNotifier<Offset> position;

  /// 손가락을 따라 움직이는 중 (이때는 애니메이션 없이 바로 따라간다).
  final ValueNotifier<bool> moving;
  final MiniFloatGeometry geometry;

  /// 길게 눌러 미니 플레이어에서 끌어내는 중인가 (아직 가장자리 영역 제한 없이 따라간다).
  final bool gripping;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    // 미리 듣는 동안은 미리 듣는 곡이 미니 플레이어 자리를 쓰므로 버튼은 숨긴다.
    final previewing = context.select(
      (PreviewCubit c) => c.state.status != PreviewStatus.idle,
    );
    final hasTrack = context.select(
      (NowPlayingCubit c) => c.state.track != null,
    );
    if (previewing || !hasTrack) return const SizedBox.shrink();
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: Listenable.merge([position, moving]),
      builder: (context, _) {
        final area = gripping ? geometry.area : geometry.safe;
        final o = MiniFloatGeometry.clampTo(area, position.value);
        return AnimatedPositioned(
          left: o.dx,
          top: o.dy,
          duration: moving.value ? Duration.zero : AppMotion.slow,
          curve: Curves.easeOutBack,
          child: TweenAnimationBuilder<double>(
            // 처음 나타날 때만 실행돼서 통통 튀며 커진다.
            tween: Tween(begin: .35, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: GestureDetector(
              key: const ValueKey('mini-float'),
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: RepaintBoundary(
                child: BlocBuilder<NowPlayingCubit, NowPlayingState>(
                  builder: (context, s) {
                    final track = s.track;
                    if (track == null) return const SizedBox.shrink();
                    return FloatingPlayerButton(
                      progress: s.progress,
                      isPlaying: s.isPlaying,
                      playLabel: l10n.actionPlay,
                      pauseLabel: l10n.actionPause,
                      expandLabel: l10n.playerFloatExpand,
                      artwork: coverImageOf(context, CoverKey.track(track.id)),
                      onPlayPause: context.read<NowPlayingCubit>().togglePlay,
                      onExpand: onExpand,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
