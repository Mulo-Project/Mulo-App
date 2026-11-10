import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/widgets/player_seek.dart';
import '../bloc/preview_cubit.dart';
import '../screens/saved_queue_screen.dart' show savedQueueLocation;

/// 상세 화면 아래의 재생 조작: 메인 플레이어와 같은 순서로 진행 막대 → 10초 · 이전 · 재생 · 다음 · 10초
/// → 셔플 · 반복 · 대기열. 높이는 화면의 3분의 1을 넘지 않는다.
class SavedQueueControls extends StatefulWidget {
  const SavedQueueControls({super.key, this.onStart});

  /// 목록 재생 중이 아닐 때(저장한 곡 상세를 그냥 열었을 때)의 시작 동작. 있으면 재생 버튼이 이걸 부르고,
  /// 이전 · 다음 · 10초 · 진행 막대는 재생이 시작될 때까지 막힌다.
  final VoidCallback? onStart;

  @override
  State<SavedQueueControls> createState() => _SavedQueueControlsState();
}

class _SavedQueueControlsState extends State<SavedQueueControls> {
  /// 끌고 있는 동안의 위치 비율 (놓을 때 한 번만 실제로 옮긴다).
  double? _scrub;

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
    final preview = context.read<PreviewCubit>();
    final (paused, loading, fraction, position, total) = context.select(
      (PreviewCubit c) => (
        c.state.paused,
        c.state.status == PreviewStatus.loading,
        c.state.fraction,
        c.state.progress?.position ?? Duration.zero,
        c.state.progress?.duration ?? Duration.zero,
      ),
    );
    final idle = widget.onStart != null;
    final shown = _scrub ?? fraction;
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
            progress: shown,
            position: _scrub == null || total == Duration.zero
                ? position
                : total * _scrub!,
            total: total,
            onSeek: (v) {
              if (!idle) setState(() => _scrub = v.clamp(0.0, 1.0));
            },
            onSeekEnd: () {
              final v = _scrub;
              setState(() => _scrub = null);
              if (v != null) preview.seekTo(v);
            },
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
                    : () => preview.seekBy(const Duration(seconds: -10)),
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-previous'),
                icon: AppIcons.skipPrevious,
                tooltip: l10n.actionPrevious,
                onPressed: idle ? null : preview.previous,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-play'),
                icon: idle || paused ? AppIcons.play : AppIcons.pause,
                tooltip: idle || paused
                    ? l10n.searchPreviewResume
                    : l10n.searchPreviewPause,
                emphasized: true,
                size: AppSizes.circleButtonLarge,
                onPressed: idle
                    ? widget.onStart
                    : loading
                    ? null
                    : preview.togglePause,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-next'),
                icon: AppIcons.skipNext,
                tooltip: l10n.actionNext,
                onPressed: idle ? null : preview.next,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-forward10'),
                icon: AppIcons.forward10,
                tooltip: l10n.playerForward10,
                onPressed: idle
                    ? null
                    : () => preview.seekBy(const Duration(seconds: 10)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ListenableBuilder(
            listenable: Listenable.merge([preview.shuffle, preview.loop]),
            builder: (context, _) => Row(
              children: [
                RowIconButton(
                  key: const ValueKey('queue-bar-shuffle'),
                  icon: AppIcons.shuffle,
                  tooltip: preview.shuffle.value
                      ? l10n.shuffleOff
                      : l10n.shuffleOn,
                  accent: preview.shuffle.value,
                  onPressed: preview.toggleShuffle,
                ),
                RowIconButton(
                  key: const ValueKey('queue-bar-loop'),
                  icon: AppIcons.repeat,
                  tooltip: l10n.playerRepeat,
                  accent: preview.loop.value,
                  onPressed: () => preview.loop.value = !preview.loop.value,
                ),
                const Spacer(),
                RowIconButton(
                  key: const ValueKey('queue-bar-queue'),
                  icon: AppIcons.queueOutline,
                  tooltip: l10n.savedQueueOpen,
                  onPressed: () => context.push(savedQueueLocation),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
