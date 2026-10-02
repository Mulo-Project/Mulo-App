import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/track_menu.dart';
import '../bloc/now_playing_cubit.dart';

/// 재생 대기열 화면: 곡 수 · 다음 곡 섞기 · 비우기, 지금 재생 중인 곡 강조,
/// 곡을 누르면 그 곡부터 재생, ⋮는 곡 메뉴(보관함과 같은 메뉴), 길게 눌러 끌면 순서가 바뀐다.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final state = context.watch<NowPlayingCubit>().state;
    final vm = context.read<NowPlayingCubit>();

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.playerQueue,
                leading: CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: l10n.actionBack,
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: state.queue.isEmpty
                    ? Center(
                        child: Text(
                          l10n.playerQueueEmpty,
                          style: text.bodyMedium?.copyWith(
                            color: p.onSurfaceMuted,
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: EdgeInsets.only(
                          bottom:
                              AppSpacing.lg +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                        header: _QueueHeader(
                          count: state.queue.length,
                          onShuffle: vm.shuffleUpNext,
                          onClear: () {
                            vm.clearQueue();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.queueCleared)),
                            );
                          },
                        ),
                        // 길게 눌러야 끌린다 (기본 손잡이는 쓰지 않는다).
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, _, _) => Material(
                          color: p.surfaceHigh,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          elevation: 0,
                          child: child,
                        ),
                        itemCount: state.queue.length,
                        onReorderItem: vm.moveInQueue,
                        itemBuilder: (context, i) {
                          final t = state.queue[i];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(t.id),
                            index: i,
                            child: _QueueTile(
                              track: t,
                              active: i == state.index,
                              playing: state.isPlaying,
                              onTap: () => vm.jumpTo(i),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 맨 위 줄: 곡 수와 안내, 다음 곡 섞기 · 대기열 비우기.
class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.count,
    required this.onShuffle,
    required this.onClear,
  });

  final int count;
  final VoidCallback onShuffle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: AppSpacing.screen.copyWith(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.songCount(count), style: text.titleMedium),
                Text(
                  l10n.queueReorderHint,
                  style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: Icons.shuffle_rounded,
            tooltip: l10n.queueShuffle,
            size: 40,
            onPressed: onShuffle,
          ),
          const SizedBox(width: AppSpacing.xs),
          CircleIconButton(
            icon: Icons.delete_sweep_rounded,
            tooltip: l10n.queueClear,
            size: 40,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

/// 대기열의 곡 한 줄. 재생 중인 곡은 강조 색 면 + 재생 표시.
class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.track,
    required this.active,
    required this.playing,
    required this.onTap,
  });

  final Track track;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final key = CoverKey.track(track.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? p.accent.withValues(alpha: .14) : null,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: TrackTile(
          title: track.title,
          subtitle: track.artist.isEmpty
              ? context.l10n.unknownArtist
              : track.artist,
          tone: toneFor(track.id),
          color: coverColorOf(context, key),
          artwork: coverImageOf(context, key),
          active: active,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    playing ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                    size: 18,
                    color: p.accent,
                  ),
                ),
              Text(formatDuration(track.duration), style: text.bodySmall),
              TrackMoreButton(track: track),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
