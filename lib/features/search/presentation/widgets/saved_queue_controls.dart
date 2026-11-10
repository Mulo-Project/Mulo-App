import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/widgets/player_seek.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/media_info.dart';
import '../bloc/preview_cubit.dart';
import '../bloc/saved_videos_cubit.dart';
import '../screens/saved_queue_screen.dart' show savedQueueLocation;

/// 상세 화면 아래의 재생 조작: 메인 플레이어와 같은 순서로 진행 막대 → 10초 · 이전 · 재생 · 다음 · 10초
/// → 셔플 · 반복 · 대기열. 높이는 화면의 3분의 1을 넘지 않는다.
class SavedQueueControls extends StatefulWidget {
  const SavedQueueControls({super.key, required this.hit});

  /// 이 조작부가 붙은 상세 화면의 곡.
  final MediaHit hit;

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

  /// 저장한 음원 전체를 목록으로 만들어 이 곡부터 튼다 (메인 재생은 멈춘다).
  void _start(BuildContext context) {
    final saved = context.read<SavedVideosCubit>().state;
    final ordered = [
      for (final v in saved)
        if (v.quality == null) v,
      for (final v in saved)
        if (v.quality != null) v,
    ];
    final start = ordered.indexWhere((v) => v.id == widget.hit.id);
    final now = context.read<NowPlayingCubit>();
    if (now.state.isPlaying) now.togglePlay();
    context.read<PreviewCubit>().playQueue([
      for (final v in ordered) PreviewQueueItem(v.hit, quality: v.quality),
    ], start: start < 0 ? 0 : start);
  }

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final preview = context.read<PreviewCubit>();
    final hit = widget.hit;
    // 이 곡이 지금 들리는(또는 준비 중인) 곡일 때만 진행 상태를 보인다. 아니면 처음 상태에서 재생을 누르면 시작한다.
    final (current, paused, loading, fraction, position, total) = context
        .select(
          (PreviewCubit c) => (
            c.state.isActive(hit.id),
            c.state.paused,
            c.state.status == PreviewStatus.loading,
            c.state.fraction,
            c.state.progress?.position ?? Duration.zero,
            c.state.progress?.duration ?? Duration.zero,
          ),
        );
    final queueOn = preview.queueActive.value;
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
            onSeek: (v) => setState(() => _scrub = v.clamp(0.0, 1.0)),
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
                onPressed: () => preview.seekBy(const Duration(seconds: -10)),
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-previous'),
                icon: AppIcons.skipPrevious,
                tooltip: l10n.actionPrevious,
                onPressed: queueOn ? preview.previous : null,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-play'),
                icon: !current || paused ? AppIcons.play : AppIcons.pause,
                tooltip: !current || paused
                    ? l10n.searchPreviewResume
                    : l10n.searchPreviewPause,
                emphasized: true,
                size: AppSizes.circleButtonLarge,
                onPressed: loading
                    ? null
                    : () => current ? preview.togglePause() : _start(context),
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-next'),
                icon: AppIcons.skipNext,
                tooltip: l10n.actionNext,
                onPressed: queueOn ? preview.next : null,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-forward10'),
                icon: AppIcons.forward10,
                tooltip: l10n.playerForward10,
                onPressed: () => preview.seekBy(const Duration(seconds: 10)),
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
