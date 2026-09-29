import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../library/domain/track.dart';
import '../../covers/presentation/cover_controller.dart';
import '../../covers/presentation/cover_sheet.dart';
import 'now_playing_view_model.dart';

/// 전체 화면 플레이어 (상세 기능: 미니·전체 화면 플레이어 #19, 기본 재생 컨트롤 #14,
/// 셔플·반복 #15, 재생 대기열 편집 #16 — 대기열은 보기 · 선택만).
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nowPlayingProvider);
    final vm = ref.read(nowPlayingProvider.notifier);
    final track = state.track;
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.playerNowPlaying,
                leading: CircleIconButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip: l10n.actionBack,
                  onPressed: () => context.pop(),
                ),
                actions: [
                  CircleIconButton(
                    icon: Icons.queue_music_rounded,
                    tooltip: l10n.playerQueue,
                    onPressed: () => _showQueue(context),
                  ),
                ],
              ),
              if (track == null)
                const Spacer()
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Hero(
                                tag: 'now-playing',
                                child: _PlayerCover(
                                  image: coverImageOf(
                                    ref,
                                    CoverKey.track(track.id),
                                  ),
                                  tone: toneFor(track.id),
                                  editLabel: l10n.coverChange,
                                  onEdit: () => showCoverSheet(
                                    context,
                                    coverKey: CoverKey.track(track.id),
                                    title: track.title,
                                    tone: toneFor(track.id),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          track.title,
                          style: text.headlineMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${track.artist} · ${track.album}',
                          style: text.bodyMedium?.copyWith(
                            color: p.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SeekBar(
                          progress: state.progress,
                          onSeek: vm.seekFraction,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            StatNumber(
                              formatDuration(state.position),
                              size: 22,
                            ),
                            const Spacer(),
                            StatNumber(
                              '-${formatDuration(track.duration - state.position)}',
                              size: 22,
                              color: p.onSurfaceMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _Controls(state: state, vm: vm),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (_) => const _QueueSheet(),
    );
  }
}

/// 누르거나 끌어서 위치를 옮기는 점선 진행 막대.
class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.progress, required this.onSeek});

  final double progress;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        void seek(Offset local) => onSeek(local.dx / c.maxWidth);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => seek(d.localPosition),
          onHorizontalDragUpdate: (d) => seek(d.localPosition),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: ProgressLine(value: progress, height: 5),
          ),
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.vm});

  final NowPlayingState state;
  final NowPlayingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    Widget toggle({
      required IconData icon,
      required String tooltip,
      required bool on,
      required VoidCallback onTap,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: on ? p.accent : p.onSurfaceMuted),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        toggle(
          icon: Icons.shuffle_rounded,
          tooltip: l10n.actionShuffle,
          on: state.shuffle,
          onTap: vm.toggleShuffle,
        ),
        CircleIconButton(
          icon: Icons.skip_previous_rounded,
          tooltip: l10n.actionPrevious,
          size: AppSizes.circleButtonLarge,
          onPressed: vm.previous,
        ),
        CircleIconButton(
          icon: state.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          tooltip: state.isPlaying ? l10n.actionPause : l10n.actionPlay,
          emphasized: true,
          size: 76,
          onPressed: vm.togglePlay,
        ),
        CircleIconButton(
          icon: Icons.skip_next_rounded,
          tooltip: l10n.actionNext,
          size: AppSizes.circleButtonLarge,
          onPressed: vm.next,
        ),
        toggle(
          icon: state.repeat == PlayerRepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          tooltip: l10n.playerRepeat,
          on: state.repeat != PlayerRepeatMode.off,
          onTap: vm.cycleRepeat,
        ),
      ],
    );
  }
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nowPlayingProvider);
    final vm = ref.read(nowPlayingProvider.notifier);
    final text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .6,
      maxChildSize: .9,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(context.l10n.playerQueue, style: text.titleLarge),
          ),
          for (var i = 0; i < state.queue.length; i++)
            TrackTile(
              title: state.queue[i].title,
              subtitle: state.queue[i].artist,
              tone: toneFor(state.queue[i].id),
              artwork: coverImageOf(ref, CoverKey.track(state.queue[i].id)),
              active: i == state.index,
              trailing: Text(
                formatDuration(state.queue[i].duration),
                style: text.bodySmall,
              ),
              onTap: () => vm.jumpTo(i),
            ),
        ],
      ),
    );
  }
}

/// 전체 화면 플레이어 커버: 이미지가 있으면 사진, 없으면 색 유리 + 음표.
/// 누르면 커버 이미지 바꾸기 시트.
class _PlayerCover extends StatelessWidget {
  const _PlayerCover({
    required this.image,
    required this.tone,
    required this.editLabel,
    required this.onEdit,
  });

  final ImageProvider? image;
  final GlowTone tone;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      children: [
        Positioned.fill(
          child: GlassCard(
            tone: tone,
            padding: EdgeInsets.zero,
            onTap: onEdit,
            child: image != null
                ? SizedBox.expand(
                    child: Image(image: image!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 96,
                      color: p.onSurface.withValues(alpha: .8),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: CircleIconButton(
            icon: Icons.edit_rounded,
            tooltip: editLabel,
            size: 40,
            onPressed: onEdit,
          ),
        ),
      ],
    );
  }
}
