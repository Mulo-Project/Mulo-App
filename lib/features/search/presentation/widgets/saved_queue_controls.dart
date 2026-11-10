import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../player/presentation/widgets/player_seek.dart';

/// 상세 화면 아래의 재생 조작: 메인 플레이어(현재 재생 목록)와 같은 순서로 진행 막대 → 10초 · 이전 · 재생 · 다음 · 10초
/// → 셔플 · 반복 · 대기열. 높이는 화면의 3분의 1을 넘지 않는다.
class SavedQueueControls extends StatelessWidget {
  const SavedQueueControls({super.key, this.onStart});

  /// 목록 재생 중이 아닐 때(저장한 곡 상세를 그냥 열었을 때)의 시작 동작. 있으면 재생 버튼이 이걸 부르고,
  /// 이전 · 다음 · 10초 · 진행 막대는 재생이 시작될 때까지 막힌다.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cap = MediaQuery.sizeOf(context).height / 3;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.outline)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: cap),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: _content(context),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final player = context.read<NowPlayingCubit>();
    final (playing, position, total, progress, shuffle, repeat) = context
        .select(
          (NowPlayingCubit c) => (
            c.state.isPlaying,
            c.state.position,
            c.state.track?.duration ?? Duration.zero,
            c.state.progress,
            c.state.shuffle,
            c.state.repeat,
          ),
        );
    final idle = onStart != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerSeekBar(
            key: const ValueKey('queue-bar-seek'),
            progress: idle ? 0 : progress,
            position: idle ? Duration.zero : position,
            total: total,
            onSeekStart: idle ? null : player.beginScrub,
            onSeek: (v) {
              if (!idle) player.seekFraction(v);
            },
            onSeekEnd: idle ? null : player.endScrub,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                key: const ValueKey('queue-bar-back10'),
                icon: AppIcons.replay10,
                tooltip: l10n.playerRewind10,
                onPressed: idle
                    ? null
                    : () => player.seekTo(
                        player.state.position - const Duration(seconds: 10),
                      ),
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-previous'),
                icon: AppIcons.skipPrevious,
                tooltip: l10n.actionPrevious,
                onPressed: idle ? null : player.previous,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-play'),
                icon: idle || !playing ? AppIcons.play : AppIcons.pause,
                tooltip: idle || !playing
                    ? l10n.searchPreviewResume
                    : l10n.searchPreviewPause,
                emphasized: true,
                size: AppSizes.circleButtonLarge,
                onPressed: idle ? onStart : player.togglePlay,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-next'),
                icon: AppIcons.skipNext,
                tooltip: l10n.actionNext,
                onPressed: idle ? null : player.next,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-forward10'),
                icon: AppIcons.forward10,
                tooltip: l10n.playerForward10,
                onPressed: idle
                    ? null
                    : () => player.seekTo(
                        player.state.position + const Duration(seconds: 10),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              RowIconButton(
                key: const ValueKey('queue-bar-shuffle'),
                icon: AppIcons.shuffle,
                tooltip: shuffle ? l10n.shuffleOff : l10n.shuffleOn,
                accent: shuffle,
                onPressed: idle ? null : player.toggleShuffle,
              ),
              RowIconButton(
                key: const ValueKey('queue-bar-loop'),
                icon: repeat == PlayerRepeatMode.one
                    ? AppIcons.repeatOne
                    : AppIcons.repeat,
                tooltip: l10n.playerRepeat,
                accent: repeat != PlayerRepeatMode.off,
                onPressed: player.cycleRepeat,
              ),
              const Spacer(),
              RowIconButton(
                key: const ValueKey('queue-bar-queue'),
                icon: AppIcons.queueOutline,
                tooltip: l10n.savedQueueOpen,
                onPressed: () => context.push(Routes.queue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
