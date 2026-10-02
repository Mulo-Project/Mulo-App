import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/track_menu.dart';
import '../../../lyrics/presentation/widgets/lyrics_view.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../bloc/now_playing_cubit.dart';

/// 플레이어 화면 하나를 그리는 데 필요한 값. 모양마다 이 값으로 배치만 다르게 한다.
class PlayerLayoutData {
  const PlayerLayoutData({
    required this.track,
    required this.state,
    required this.vm,
    required this.showLyrics,
    required this.onToggleLyrics,
  });

  final Track track;
  final NowPlayingState state;
  final NowPlayingCubit vm;
  final bool showLyrics;
  final VoidCallback onToggleLyrics;
}

/// 지금 곡의 커버 이미지 · 색. 배경 그라데이션도 여기서 뽑는다.
class PlayerArt {
  const PlayerArt({
    required this.image,
    required this.tone,
    required this.color,
    required this.glow,
  });

  factory PlayerArt.of(BuildContext context, Track track) {
    final key = CoverKey.track(track.id);
    final tone = toneFor(track.id);
    final color = coverColorOf(context, key);
    return PlayerArt(
      image: coverImageOf(context, key),
      tone: tone,
      color: color,
      glow: color != null ? glowFromColor(color) : context.tokens.glow(tone),
    );
  }

  final ImageProvider? image;
  final GlowTone tone;
  final Color? color;

  /// 밝은 → 어두운 3색.
  final List<Color> glow;
}

/// 플레이어 바탕: 커버(또는 테마) 색이 위에서 배경색으로 스며드는 그라데이션.
/// [blurred]면 커버 이미지를 흐리게 깔아 쓴다 (이미지가 없으면 더 진한 그라데이션).
class PlayerBackdrop extends StatelessWidget {
  const PlayerBackdrop({
    super.key,
    required this.art,
    required this.child,
    this.blurred = false,
  });

  final PlayerArt art;
  final bool blurred;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final image = blurred ? art.image : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.background),
        if (image != null) ...[
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: Image(image: image, fit: BoxFit.cover),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  p.background.withValues(alpha: .45),
                  p.background.withValues(alpha: .78),
                  p.background,
                ],
                stops: const [0, .6, 1],
              ),
            ),
          ),
        ] else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  art.glow[1].withValues(alpha: .9),
                  Color.lerp(art.glow[2], p.background, .35)!,
                  p.background,
                ],
                stops: const [0, .55, 1],
              ),
            ),
          ),
        child,
      ],
    );
  }
}

/// 맨 위 줄: 내리기 · 제목 · (더 보기).
class PlayerTopBar extends StatelessWidget {
  const PlayerTopBar({super.key, required this.track, this.showMore = true});

  final Track track;
  final bool showMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppTopBar(
      title: l10n.playerNowPlaying,
      leading: CircleIconButton(
        icon: Icons.keyboard_arrow_down_rounded,
        tooltip: l10n.actionBack,
        onPressed: () => context.pop(),
      ),
      actions: [if (showMore) PlayerMoreButton(track: track)],
    );
  }
}

/// 곡 메뉴 (보관함 곡 목록의 ⋮ 와 같은 메뉴).
class PlayerMoreButton extends StatelessWidget {
  const PlayerMoreButton({super.key, required this.track, this.circle = true});

  final Track track;

  /// false면 유리 버튼 대신 맨 아이콘.
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Builder(
      builder: (btn) => circle
          ? CircleIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: l10n.trackMenuTitle,
              onPressed: () => showTrackMenu(btn, track, inPlayer: true),
            )
          : IconButton(
              tooltip: l10n.trackMenuTitle,
              onPressed: () => showTrackMenu(btn, track, inPlayer: true),
              icon: Icon(
                Icons.more_vert_rounded,
                color: context.palette.onSurface,
              ),
            ),
    );
  }
}

/// 곡 제목 · 아티스트(· 앨범).
class PlayerTitle extends StatelessWidget {
  const PlayerTitle({
    super.key,
    required this.track,
    this.center = false,
    this.large = true,
    this.withAlbum = true,
  });

  final Track track;
  final bool center;

  /// true면 큰 제목(화면 주인공), false면 한 줄 작은 제목.
  final bool large;
  final bool withAlbum;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          track.title,
          style: (large ? text.headlineSmall : text.titleMedium)?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
        ),
        SizedBox(height: large ? AppSpacing.xxs + 2 : 2),
        Text(
          [
            track.artist.isEmpty ? l10n.unknownArtist : track.artist,
            if (withAlbum && track.album.isNotEmpty) track.album,
          ].join(' · '),
          style: (large ? text.bodyLarge : text.bodySmall)?.copyWith(
            color: p.onSurface.withValues(alpha: .66),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
        ),
      ],
    );
  }
}

/// 커버 이미지가 있으면 사진, 없으면 테마 색 그라데이션 + 음표.
class PlayerCover extends StatelessWidget {
  const PlayerCover({
    super.key,
    required this.art,
    this.radius = AppRadii.lg,
    this.icon = true,
  });

  final PlayerArt art;
  final double radius;

  /// 이미지가 없을 때 가운데 음표를 그릴지.
  final bool icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CoverCard(
      radius: radius,
      image: art.image,
      tone: art.tone,
      color: art.color,
      child: art.image != null || !icon
          ? null
          : LayoutBuilder(
              builder: (context, c) => Center(
                child: Icon(
                  Icons.music_note_rounded,
                  size: math.min(c.maxWidth, c.maxHeight) * .34,
                  color: p.onGlow.withValues(alpha: .85),
                ),
              ),
            ),
    );
  }
}

/// 가사 보기: 커버 자리를 가사가 대신한다.
class PlayerLyricsPane extends StatelessWidget {
  const PlayerLyricsPane({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) => LyricsView(track: track);
}

/// 누르거나 끌어서 위치를 옮기는 가는 진행 막대 (끝에 흰 손잡이).
class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    required this.progress,
    required this.onSeek,
  });

  final double progress;
  final ValueChanged<double> onSeek;

  static const _knob = 14.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) {
        void seek(Offset local) => onSeek(local.dx / c.maxWidth);
        final v = progress.clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => seek(d.localPosition),
          onHorizontalDragUpdate: (d) => seek(d.localPosition),
          child: SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 4,
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: p.onSurface.withValues(alpha: .2),
                  ),
                ),
                Container(
                  height: 4,
                  width: c.maxWidth * v,
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: p.onSurface,
                  ),
                ),
                Positioned(
                  left: (c.maxWidth - _knob) * v,
                  child: Container(
                    width: _knob,
                    height: _knob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.onSurface,
                      boxShadow: [
                        BoxShadow(
                          color: p.scrim.withValues(alpha: .3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 지난 시간 · 남은 시간.
class PlayerTimes extends StatelessWidget {
  const PlayerTimes({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: context.palette.onSurface.withValues(alpha: .66));
    return Row(
      children: [
        Text(formatDuration(data.state.position), style: style),
        const Spacer(),
        Text(
          '-${formatDuration(data.track.duration - data.state.position)}',
          style: style,
        ),
      ],
    );
  }
}

/// "02:15 / 44:39" 글자.
class TimeText extends StatelessWidget {
  const TimeText({super.key, required this.data});

  final PlayerLayoutData data;

  static String clock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$sec' : '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: clock(data.state.position)),
          TextSpan(
            text: ' / ${clock(data.track.duration)}',
            style: TextStyle(color: p.onSurface.withValues(alpha: .6)),
          ),
        ],
      ),
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}

/// 좋아요 하트: 좋아요 목록에 넣고 뺀다.
class PlayerLikeButton extends StatelessWidget {
  const PlayerLikeButton({super.key, required this.trackId});

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

/// 가사 보기 ↔ 커버 보기.
class LyricsToggleButton extends StatelessWidget {
  const LyricsToggleButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return IconButton(
      tooltip: data.showLyrics ? l10n.playerShowCover : l10n.playerShowLyrics,
      onPressed: data.onToggleLyrics,
      icon: Icon(
        data.showLyrics ? Icons.album_rounded : Icons.lyrics_rounded,
        color: data.showLyrics ? p.accent : p.onSurfaceMuted,
      ),
    );
  }
}

/// 재생 대기열 화면 열기.
class QueueButton extends StatelessWidget {
  const QueueButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.playerQueue,
    onPressed: () => context.push(Routes.queue),
    icon: Icon(
      Icons.queue_music_rounded,
      color: context.palette.onSurfaceMuted,
    ),
  );
}

/// 셔플 토글.
class ShuffleButton extends StatelessWidget {
  const ShuffleButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.actionShuffle,
    onPressed: data.vm.toggleShuffle,
    icon: Icon(
      Icons.shuffle_rounded,
      color: data.state.shuffle
          ? context.palette.accent
          : context.palette.onSurfaceMuted,
    ),
  );
}

/// 반복 (끔 → 전체 → 한 곡).
class RepeatButton extends StatelessWidget {
  const RepeatButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final repeat = data.state.repeat;
    return IconButton(
      tooltip: context.l10n.playerRepeat,
      onPressed: data.vm.cycleRepeat,
      icon: Icon(
        repeat == PlayerRepeatMode.one
            ? Icons.repeat_one_rounded
            : Icons.repeat_rounded,
        color: repeat != PlayerRepeatMode.off ? p.accent : p.onSurfaceMuted,
      ),
    );
  }
}

/// 이전 · 다음 (맨 아이콘).
class SkipButton extends StatelessWidget {
  const SkipButton({
    super.key,
    required this.data,
    required this.next,
    this.color,
  });

  final PlayerLayoutData data;
  final bool next;

  /// 아이콘 색 (없으면 테마 글자색).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      iconSize: 40,
      tooltip: next ? l10n.actionNext : l10n.actionPrevious,
      onPressed: next ? data.vm.next : data.vm.previous,
      icon: Icon(
        next ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
        color: color ?? context.palette.onSurface,
      ),
    );
  }
}

/// 흰(테마 글자색) 원 재생 버튼.
class SolidPlayButton extends StatelessWidget {
  const SolidPlayButton({super.key, required this.data, this.size = 68});

  final PlayerLayoutData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final playing = data.state.isPlaying;
    return Tooltip(
      message: playing ? l10n.actionPause : l10n.actionPlay,
      child: Material(
        color: p.onSurface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: data.vm.togglePlay,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: size * .52,
              color: p.background,
            ),
          ),
        ),
      ),
    );
  }
}

/// 강조 색 빛나는 재생 버튼.
class GlowPlayButton extends StatelessWidget {
  const GlowPlayButton({super.key, required this.data, this.size = 84});

  final PlayerLayoutData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final playing = data.state.isPlaying;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.palette.accent.withValues(alpha: .4),
            blurRadius: size * .6,
            spreadRadius: size * .06,
          ),
        ],
      ),
      child: CircleIconButton(
        icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        tooltip: playing ? l10n.actionPause : l10n.actionPlay,
        emphasized: true,
        size: size,
        onPressed: data.vm.togglePlay,
      ),
    );
  }
}

/// 10초 뒤로 · 앞으로.
class SeekStepButton extends StatelessWidget {
  const SeekStepButton({
    super.key,
    required this.data,
    required this.forward,
    this.color,
  });

  final PlayerLayoutData data;
  final bool forward;

  /// 아이콘 색 (없으면 테마 글자색).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const step = Duration(seconds: 10);
    return IconButton(
      iconSize: 28,
      tooltip: forward ? l10n.playerForward10 : l10n.playerRewind10,
      onPressed: () => data.vm.seekTo(
        forward ? data.state.position + step : data.state.position - step,
      ),
      icon: Icon(
        forward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
        color: color ?? context.palette.onSurface.withValues(alpha: .85),
      ),
    );
  }
}

/// 재생목록에 추가 (재생목록 고르기 화면으로 간다).
class AddToPlaylistButton extends StatelessWidget {
  const AddToPlaylistButton({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.trackMenuAddToPlaylist,
    onPressed: () => context.push(Routes.playlistPick, extra: [trackId]),
    icon: Icon(
      Icons.playlist_add_rounded,
      color: context.palette.onSurfaceMuted,
    ),
  );
}

/// 수면 타이머: 15 · 30 · 45 · 60분 뒤에 재생을 멈춘다.
class SleepTimerButton extends StatelessWidget {
  const SleepTimerButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final on = data.state.sleepMinutes != null;
    return Builder(
      builder: (btn) => IconButton(
        tooltip: l10n.playerSleepTimer,
        onPressed: () async {
          final picked = await showAppMenu<int>(
            btn,
            items: [
              for (final m in const [15, 30, 45, 60])
                AppMenuItem(
                  value: m,
                  icon: Icons.bedtime_rounded,
                  label: l10n.playerSleepTimerMinutes(m),
                  selected: data.state.sleepMinutes == m,
                ),
              if (on)
                AppMenuItem(
                  value: 0,
                  icon: Icons.timer_off_rounded,
                  label: l10n.playerSleepTimerOff,
                  dividerBefore: true,
                ),
            ],
          );
          if (picked == null || !btn.mounted) return;
          data.vm.setSleepTimer(picked == 0 ? null : picked);
          ScaffoldMessenger.of(btn).hideCurrentSnackBar();
          ScaffoldMessenger.of(btn).showSnackBar(
            SnackBar(
              content: Text(
                picked == 0
                    ? l10n.playerSleepTimerCleared
                    : l10n.playerSleepTimerSet(picked),
              ),
            ),
          );
        },
        icon: Icon(
          on ? Icons.bedtime_rounded : Icons.bedtime_outlined,
          color: on ? p.accent : p.onSurfaceMuted,
        ),
      ),
    );
  }
}

/// 이퀄라이저 (아직 준비 중).
class EqualizerButton extends StatelessWidget {
  const EqualizerButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.playerEqualizer,
    onPressed: () => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.playerEqualizerSoon))),
    icon: Icon(Icons.equalizer_rounded, color: context.palette.onSurfaceMuted),
  );
}

/// 모든 모양이 같이 쓰는 하단 조작부 (위에서 아래로):
/// 1) 제목 · 아티스트 + 가사/커버 · 재생목록에 추가 · 좋아요
/// 2) 10초 뒤로 · 진행 막대(+시간) · 10초 앞으로
/// 3) 이전 · 재생 · 다음
/// 4) 셔플 · 반복 (왼쪽), 수면 타이머 · 이퀄라이저 · 대기열 (오른쪽)
///
/// [seekBar]가 false면 진행 막대는 커버 쪽(호 · 커스텀)에 있어, 2줄 가운데엔 시간만 둔다.
/// [neu]면 이전 · 다음 · 10초 버튼을 볼록한 원 위에 얹는다 (커스텀).
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.data,
    required this.play,
    this.seekBar = true,
    this.neu = false,
  });

  final PlayerLayoutData data;
  final Widget play;
  final bool seekBar;
  final bool neu;

  @override
  Widget build(BuildContext context) {
    final tint = neu ? context.palette.accent : null;
    Widget wrap(Widget w, double size) =>
        neu ? NeuCircle(size: size, child: w) : w;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: PlayerTitle(track: data.track, withAlbum: false)),
              IconButtonTheme(
                data: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    iconSize: 22,
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LyricsToggleButton(data: data),
                    AddToPlaylistButton(trackId: data.track.id),
                    PlayerLikeButton(trackId: data.track.id),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              wrap(SeekStepButton(data: data, forward: false, color: tint), 44),
              Expanded(
                child: seekBar
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PlayerSeekBar(
                              progress: data.state.progress,
                              onSeek: data.vm.seekFraction,
                            ),
                            PlayerTimes(data: data),
                          ],
                        ),
                      )
                    : Center(child: TimeText(data: data)),
              ),
              wrap(SeekStepButton(data: data, forward: true, color: tint), 44),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              wrap(SkipButton(data: data, next: false, color: tint), 56),
              play,
              wrap(SkipButton(data: data, next: true, color: tint), 56),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              ShuffleButton(data: data),
              RepeatButton(data: data),
              const Spacer(),
              SleepTimerButton(data: data),
              const EqualizerButton(),
              const QueueButton(),
            ],
          ),
        ],
      ),
    );
  }
}

/// 소프트(뉴모피즘) 볼록 그림자: 오른쪽 아래는 어둡게, 왼쪽 위는 밝게.
List<BoxShadow> neuShadows(BuildContext context, {double depth = 6}) {
  final p = context.palette;
  final light = Theme.of(context).brightness == Brightness.light;
  return [
    BoxShadow(
      color: p.scrim.withValues(alpha: light ? .16 : .55),
      offset: Offset(depth, depth),
      blurRadius: depth * 2.2,
    ),
    BoxShadow(
      color: light
          ? AppPalette.white.withValues(alpha: .95)
          : p.onSurface.withValues(alpha: .06),
      offset: Offset(-depth, -depth),
      blurRadius: depth * 2.2,
    ),
  ];
}

/// 볼록하게 떠 있는 원 (커스텀 모양의 버튼 바탕).
class NeuCircle extends StatelessWidget {
  const NeuCircle({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.palette.surface,
      boxShadow: neuShadows(context, depth: size * .08),
    ),
    child: SizedBox.square(
      dimension: size,
      child: Center(child: child),
    ),
  );
}

/// 원 둘레를 누르거나 끌어서 위치를 옮기는 영역 ([child]는 원 안쪽).
///
/// [start]에서 시계 방향으로 [sweep]만큼이 0 ~ 1. 원 안쪽([inner] 비율 이하)을
/// 눌러 시작한 것은 무시한다 (가운데 버튼과 겹치지 않게).
class RingSeek extends StatefulWidget {
  const RingSeek({
    super.key,
    required this.size,
    required this.start,
    required this.sweep,
    required this.onSeek,
    this.inner = .7,
    this.child,
  });

  final double size;
  final double start;
  final double sweep;
  final double inner;
  final ValueChanged<double> onSeek;
  final Widget? child;

  /// [local]이 가리키는 호 위의 위치(0 ~ 1). 호가 열린 쪽은 가까운 끝으로 붙인다.
  static double fractionAt(
    Offset local,
    Size size, {
    required double start,
    required double sweep,
  }) {
    final d = local - size.center(Offset.zero);
    final rel = (math.atan2(d.dy, d.dx) - start) % (2 * math.pi);
    if (rel <= sweep) return rel / sweep;
    return rel - sweep < (2 * math.pi - sweep) / 2 ? 1 : 0;
  }

  @override
  State<RingSeek> createState() => _RingSeekState();
}

class _RingSeekState extends State<RingSeek> {
  var _dragging = false;

  bool _onRing(Offset local) {
    final d = (local - Offset(widget.size / 2, widget.size / 2)).distance;
    return d >= widget.size / 2 * widget.inner;
  }

  void _seek(Offset local) => widget.onSeek(
    RingSeek.fractionAt(
      local,
      Size.square(widget.size),
      start: widget.start,
      sweep: widget.sweep,
    ),
  );

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTapDown: (d) {
      if (_onRing(d.localPosition)) _seek(d.localPosition);
    },
    onPanStart: (d) {
      _dragging = _onRing(d.localPosition);
      if (_dragging) _seek(d.localPosition);
    },
    onPanUpdate: (d) {
      if (_dragging) _seek(d.localPosition);
    },
    onPanEnd: (_) => _dragging = false,
    child: SizedBox.square(dimension: widget.size, child: widget.child),
  );
}

/// 가는 원형 진행 호 + 끝의 손잡이.
/// [start]에서 시계 방향으로 [sweep]만큼이 0 ~ 1 (기본: 12시 방향에서 한 바퀴).
class ThinRingPainter extends CustomPainter {
  ThinRingPainter({
    required this.value,
    required this.track,
    required this.fill,
    required this.shadow,
    this.stroke = 3,
    this.knob = 6,
    this.start = -math.pi / 2,
    this.sweep = 2 * math.pi,
  });

  final double value;
  final Color track;
  final Color fill;
  final Color shadow;
  final double stroke;

  /// 손잡이 반지름.
  final double knob;
  final double start;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - knob - 1;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, line..color = track);
    final v = value.clamp(0.0, 1.0);
    final done = sweep * v;
    if (done > 0) {
      canvas.drawArc(rect, start, done, false, line..color = fill);
    }
    final end = center + Offset.fromDirection(start + done, radius);
    canvas.drawCircle(
      end,
      knob,
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(end, knob, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(ThinRingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.shadow != shadow ||
      old.start != start ||
      old.sweep != sweep;
}
