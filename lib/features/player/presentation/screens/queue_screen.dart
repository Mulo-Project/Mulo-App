import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/library_selection.dart';
import '../../../library/presentation/widgets/track_list_tile.dart'
    show TrackSelection, selectionMark;
import '../../../library/presentation/widgets/track_menu.dart';
import '../bloc/now_playing_cubit.dart';

/// 비우기 확인창. 확인하면 재생도 멈추고 대기열을 모두 비운다.
Future<bool> _confirmClear(BuildContext context) async {
  final l10n = context.l10n;
  final vm = context.read<NowPlayingCubit>();
  final ok = await showConfirmDialog(
    context,
    title: l10n.queueClearTitle,
    body: l10n.queueClearBody,
    confirmLabel: l10n.queueClearConfirm,
    confirmIcon: AppIcons.delete,
    cancelLabel: l10n.actionCancel,
  );
  if (ok) vm.clearQueue();
  return ok;
}

/// 재생 대기열 화면: 곡 수 · 셔플 켜기/끄기 · 비우기(위에 고정), 지금 재생 중인 곡 강조,
/// 곡을 누르면 그 곡부터 재생, ⋮는 곡 메뉴(보관함과 같은 메뉴), 길게 눌러 끌면 순서가 바뀐다.
/// 줄 길게 누르기는 끌기에 쓰이므로, 여러 곡 선택은 맨 위 "선택" 버튼으로 모드에 들어간다.
/// 선택 모드에서는 순서 바꾸기를 잠그고, 누르면 고르거나 푼다.
class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen>
    with TrackPicker<QueueScreen> {
  /// "선택" 버튼으로 들어온 선택 모드 (아직 아무 곡도 안 골랐어도 모드는 켜져 있다).
  bool _mode = false;

  @override
  bool get selecting => _mode || picked.isNotEmpty;

  @override
  bool get pickerInQueue => true;

  @override
  void clearPicked() {
    _mode = false;
    super.clearPicked();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    // 재생 위치(초마다 바뀜)는 보지 않는다: 끄는 동안 목록이 다시 그려지면 끊긴다.
    final (queue, index, playing, shuffle, repeat) = context.select(
      (NowPlayingCubit c) => (
        c.state.queue,
        c.state.index,
        c.state.isPlaying,
        c.state.shuffle,
        c.state.repeat,
      ),
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
                leading: const AppBackButton(),
              ),
              // 곡 수 · 섞기 · 비우기 줄은 목록이 스크롤돼도 고정한다.
              if (queue.isNotEmpty)
                QueueHeader(
                  count: queue.length,
                  shuffle: shuffle,
                  onShuffle: vm.toggleShuffle,
                  repeat: repeat,
                  onRepeat: vm.cycleRepeat,
                  onClear: () async {
                    if (await _confirmClear(context) && mounted) clearPicked();
                  },
                  onSelect: selecting
                      ? null
                      : () => setState(() => _mode = true),
                ),
              Expanded(
                child: queue.isEmpty
                    ? EmptyState(title: l10n.playerQueueEmpty)
                    : Stack(
                        children: [
                          ReorderableListView.builder(
                            padding: EdgeInsets.only(
                              bottom:
                                  AppSpacing.lg +
                                  MediaQuery.paddingOf(context).bottom +
                                  selectionBottomGap,
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
                                enabled: !selecting,
                                child: _QueueTile(
                                  track: t,
                                  number: i + 1,
                                  active: i == index,
                                  playing: playing,
                                  selection: selecting ? selectionFor(t) : null,
                                  onTap: () => vm.jumpTo(i),
                                ),
                              );
                            },
                          ),
                          ?selectionBar(queue, queue),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 맨 위 줄: 곡 수와 안내, 셔플 켜기/끄기 · 반복(플레이어의 셔플 · 반복과 같은 설정) · 대기열 비우기.
class QueueHeader extends StatelessWidget {
  const QueueHeader({
    super.key,
    required this.count,
    required this.shuffle,
    required this.onShuffle,
    required this.repeat,
    required this.onRepeat,
    required this.onClear,
    this.hint,
    this.onSelect,
    this.showSelect = true,
  });

  final int count;

  /// 셔플이 켜져 있는지 (켜져 있으면 강조 색).
  final bool shuffle;
  final VoidCallback onShuffle;

  /// 반복 모드 (끔 → 전체 → 한 곡): 켜져 있으면 강조 색, 한 곡이면 "1" 표시 아이콘.
  final PlayerRepeatMode repeat;
  final VoidCallback onRepeat;
  final VoidCallback onClear;

  /// 곡 수 밑 안내 문구 (기본은 순서 바꾸기 안내).
  final String? hint;

  /// 여러 곡 선택 모드로 들어간다 (선택 모드 중에는 null).
  final VoidCallback? onSelect;

  /// 여러 곡 선택 버튼을 보일지 (선택을 안 쓰는 목록은 끈다).
  final bool showSelect;

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
                  hint ?? l10n.queueReorderHint,
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
            icon: repeat == PlayerRepeatMode.one
                ? AppIcons.repeatOne
                : AppIcons.repeat,
            tooltip: l10n.playerRepeat,
            accent: repeat != PlayerRepeatMode.off,
            onPressed: onRepeat,
          ),
          if (showSelect)
            RowIconButton(
              icon: AppIcons.checkCircle,
              tooltip: l10n.queueSelect,
              onPressed: onSelect,
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
    this.selection,
  });

  final Track track;
  final int number;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  /// 선택 모드일 때만 있다: 누르면 고르거나 풀고, 오른쪽에 체크가 보인다.
  final TrackSelection? selection;

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
          trailing: selection != null
              ? selectionMark(context, selection!)
              : Row(
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
                    // 임시 저장한 음원(cache)은 일반 곡과 구분되게 작은 표시를 붙인다.
                    if (track.isSaved)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Tooltip(
                          message: context.l10n.savedVideosTitle,
                          child: Icon(
                            AppIcons.download,
                            size: AppSizes.iconSm,
                            color: p.onSurfaceMuted,
                          ),
                        ),
                      ),
                    Text(formatDuration(track.duration), style: text.bodySmall),
                    TrackMoreButton(track: track, inQueue: true),
                  ],
                ),
          onTap: selection?.onToggle ?? onTap,
        ),
      ),
    );
  }
}
