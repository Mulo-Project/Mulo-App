import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../app/router.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/track_menu.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../lyrics/presentation/widgets/lyrics_view.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../bloc/now_playing_cubit.dart';

/// 전체 화면 플레이어 (상세 기능: 미니·전체 화면 플레이어 #19, 기본 재생 컨트롤 #14,
/// 셔플·반복 #15, 재생 대기열 편집 #16 — 대기열은 보기 · 선택만).
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  /// 커버 ↔ 가사 전환 (상세 기능: 가사).
  var _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NowPlayingCubit>().state;
    final vm = context.read<NowPlayingCubit>();
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
                // 보관함 곡 목록의 ⋮ 와 같은 곡 메뉴.
                actions: [
                  if (track != null)
                    Builder(
                      builder: (btn) => CircleIconButton(
                        icon: Icons.more_vert_rounded,
                        tooltip: l10n.trackMenuTitle,
                        onPressed: () => showTrackMenu(btn, track),
                      ),
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
                          child: _showLyrics
                              ? LyricsView(track: track)
                              : Center(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Hero(
                                      tag: 'now-playing',
                                      child: _PlayerCover(
                                        image: coverImageOf(
                                          context,
                                          CoverKey.track(track.id),
                                        ),
                                        tone: toneFor(track.id),
                                        color: coverColorOf(
                                          context,
                                          CoverKey.track(track.id),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // 커버와 제목 사이: 가사 · 재생 대기열.
                        _ViewTools(
                          showLyrics: _showLyrics,
                          onToggleLyrics: () =>
                              setState(() => _showLyrics = !_showLyrics),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // 구역 1: 곡 정보 · 좋아요 · 진행 막대.
                        GlassCard(
                          glow: false,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.xs,
                            AppSpacing.xs,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.title,
                                          style: text.titleLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          [
                                            track.artist.isEmpty
                                                ? l10n.unknownArtist
                                                : track.artist,
                                            if (track.album.isNotEmpty)
                                              track.album,
                                          ].join(' · '),
                                          style: text.bodyMedium?.copyWith(
                                            color: p.onSurfaceMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _LikeButton(trackId: track.id),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.sm,
                                ),
                                child: Column(
                                  children: [
                                    _SeekBar(
                                      progress: state.progress,
                                      onSeek: vm.seekFraction,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          formatDuration(state.position),
                                          style: text.labelMedium?.copyWith(
                                            color: p.onSurfaceMuted,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '-${formatDuration(track.duration - state.position)}',
                                          style: text.labelMedium?.copyWith(
                                            color: p.onSurfaceMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // 구역 2: 재생 컨트롤 (셔플 · 이전 · 재생 · 다음 · 반복).
                        GlassCard(
                          glow: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          child: _Controls(state: state, vm: vm),
                        ),
                        const SizedBox(height: AppSpacing.md),
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
            child: ProgressLine(value: progress, height: 4),
          ),
        );
      },
    );
  }
}

/// 재생 줄: 셔플 · 이전 · 재생/일시정지 · 다음 · 반복.
class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.vm});

  final NowPlayingState state;
  final NowPlayingCubit vm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    Widget side(IconData icon, String tooltip, bool on, VoidCallback onTap) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, color: on ? p.accent : p.onSurfaceMuted),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        side(
          Icons.shuffle_rounded,
          l10n.actionShuffle,
          state.shuffle,
          vm.toggleShuffle,
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
          size: 72,
          onPressed: vm.togglePlay,
        ),
        CircleIconButton(
          icon: Icons.skip_next_rounded,
          tooltip: l10n.actionNext,
          size: AppSizes.circleButtonLarge,
          onPressed: vm.next,
        ),
        side(
          state.repeat == PlayerRepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          l10n.playerRepeat,
          state.repeat != PlayerRepeatMode.off,
          vm.cycleRepeat,
        ),
      ],
    );
  }
}

/// 커버와 제목 사이 줄: 가사 보기 · 재생 대기열.
class _ViewTools extends StatelessWidget {
  const _ViewTools({required this.showLyrics, required this.onToggleLyrics});

  final bool showLyrics;
  final VoidCallback onToggleLyrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: showLyrics ? l10n.playerShowCover : l10n.playerShowLyrics,
          onPressed: onToggleLyrics,
          icon: Icon(
            showLyrics ? Icons.album_rounded : Icons.lyrics_rounded,
            color: showLyrics ? p.accent : p.onSurfaceMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        IconButton(
          tooltip: l10n.playerQueue,
          onPressed: () => context.push(Routes.queue),
          icon: Icon(Icons.queue_music_rounded, color: p.onSurfaceMuted),
        ),
      ],
    );
  }
}

/// 좋아요 하트: 곡 정보 오른쪽. 좋아요 목록에 넣고 뺀다.
class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final cubit = context.read<PlaylistsCubit>();
    return BlocBuilder<PlaylistsCubit, List<Playlist>>(
      builder: (context, _) {
        final on = cubit.isFavorite(trackId);
        return IconButton(
          tooltip: on ? l10n.trackMenuUnfavorite : l10n.trackMenuFavorite,
          onPressed: () => cubit.toggleFavorite(trackId),
          icon: Icon(
            on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: on ? p.accent : p.onSurfaceMuted,
          ),
        );
      },
    );
  }
}

/// 전체 화면 플레이어 커버: 이미지가 있으면 사진, 없으면 테마 색 그라데이션 + 음표.
/// 커버 이미지는 곡 타일 메뉴에서만 바꾼다.
class _PlayerCover extends StatelessWidget {
  const _PlayerCover({required this.image, required this.tone, this.color});

  final ImageProvider? image;
  final GlowTone tone;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CoverCard(
      radius: AppRadii.sm,
      image: image,
      tone: tone,
      color: color,
      child: image != null
          ? null
          : Center(
              child: Icon(
                Icons.music_note_rounded,
                size: 96,
                color: p.onGlow.withValues(alpha: .85),
              ),
            ),
    );
  }
}
