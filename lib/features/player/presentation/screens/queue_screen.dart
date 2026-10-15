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

/// 비우기 확인창. 확인하면 재생도 멈추고 대기열을 모두 비운다.
Future<void> _confirmClear(BuildContext context) async {
  final l10n = context.l10n;
  final vm = context.read<NowPlayingCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const _ClearDialog(),
  );
  if (ok != true) return;
  vm.clearQueue();
  messenger.showSnackBar(SnackBar(content: Text(l10n.queueCleared)));
}

class _ClearDialog extends StatelessWidget {
  const _ClearDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.queueClearTitle,
      body: l10n.queueClearBody,
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PillButton(
          label: l10n.queueClearConfirm,
          icon: AppIcons.delete,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// 재생 대기열 화면: 곡 수 · 셔플 켜기/끄기 · 비우기(위에 고정), 지금 재생 중인 곡 강조,
/// 곡을 누르면 그 곡부터 재생, ⋮는 곡 메뉴(보관함과 같은 메뉴), 길게 눌러 끌면 순서가 바뀐다.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    // 재생 위치(초마다 바뀜)는 보지 않는다: 끄는 동안 목록이 다시 그려지면 끊긴다.
    final (queue, index, playing, shuffle) = context.select(
      (NowPlayingCubit c) =>
          (c.state.queue, c.state.index, c.state.isPlaying, c.state.shuffle),
    );
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
                  icon: AppIcons.back,
                  tooltip: l10n.actionBack,
                  onPressed: () => context.pop(),
                ),
              ),
              // 곡 수 · 섞기 · 비우기 줄은 목록이 스크롤돼도 고정한다.
              if (queue.isNotEmpty)
                _QueueHeader(
                  count: queue.length,
                  shuffle: shuffle,
                  onShuffle: vm.toggleShuffle,
                  onClear: () => _confirmClear(context),
                ),
              Expanded(
                child: queue.isEmpty
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
                        // 길게 눌러야 끌린다 (기본 손잡이는 쓰지 않는다).
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, _, _) => Material(
                          color: p.surfaceHigh,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          elevation: 0,
                          child: child,
                        ),
                        itemCount: queue.length,
                        onReorderItem: vm.moveInQueue,
                        itemBuilder: (context, i) {
                          final t = queue[i];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(t.id),
                            index: i,
                            child: _QueueTile(
                              track: t,
                              number: i + 1,
                              active: i == index,
                              playing: playing,
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

/// 맨 위 줄: 곡 수와 안내, 셔플 켜기/끄기(플레이어의 셔플과 같은 설정) · 대기열 비우기.
class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.count,
    required this.shuffle,
    required this.onShuffle,
    required this.onClear,
  });

  final int count;

  /// 셔플이 켜져 있는지 (켜져 있으면 강조 색).
  final bool shuffle;
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
          RowIconButton(
            icon: AppIcons.shuffle,
            tooltip: shuffle ? l10n.shuffleOff : l10n.shuffleOn,
            accent: shuffle,
            onPressed: onShuffle,
          ),
          RowIconButton(
            icon: AppIcons.deleteAll,
            tooltip: l10n.queueClear,
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
    required this.number,
    required this.active,
    required this.playing,
    required this.onTap,
  });

  final Track track;
  final int number;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final key = CoverKey.track(track.id);

    // 바깥 xs + 안쪽 xs = 16: 번호가 위 곡 수 글자와 같은 왼쪽 선에서 시작한다.
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
          number: number,
          horizontalPadding: AppSpacing.xs,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    playing ? AppIcons.equalizer : AppIcons.pause,
                    size: AppSizes.iconSm,
                    color: p.accent,
                  ),
                ),
              Text(formatDuration(track.duration), style: text.bodySmall),
              TrackMoreButton(track: track, inQueue: true),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
