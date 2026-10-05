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

/// 기본 원형 손잡이 + 아래로 이어지는 둥근 삼각형 + 현재 재생 시간 상자를 한 덩어리로 그린 손잡이.
/// 총 재생 시간은 막대 위 오른쪽.
class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    required this.progress,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    required this.position,
    required this.total,
  });

  final double progress;
  final ValueChanged<double> onSeek;

  /// 끌기(또는 누르기) 시작 · 끝. 끝날 때 한 번만 실제로 옮기는 데 쓴다.
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final Duration position;
  final Duration total;

  static const _knob = 14.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: p.onSurface.withValues(alpha: .7));
    return LayoutBuilder(
      builder: (context, c) {
        final room = c.maxWidth - TimeThumb.edge * 2 - _knob;
        void seek(Offset local) => onSeek((local.dx - _knob / 2) / room);
        final v = progress.clamp(0.0, 1.0);
        final knobX = room * v + _knob / 2;
        final thumbX = knobX - TimeThumb.width / 2;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: TimeThumb.edge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(TimeText.clock(total), style: style),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  onSeekStart?.call();
                  seek(d.localPosition);
                },
                onTapUp: (_) => onSeekEnd?.call(),
                onTapCancel: () => onSeekEnd?.call(),
                onHorizontalDragStart: (_) => onSeekStart?.call(),
                onHorizontalDragUpdate: (d) => seek(d.localPosition),
                onHorizontalDragEnd: (_) => onSeekEnd?.call(),
                onHorizontalDragCancel: () => onSeekEnd?.call(),
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
                        width: knobX,
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: p.onSurface,
                        ),
                      ),
                      Positioned(
                        left: thumbX,
                        top: 14 - TimeThumb.knobR,
                        child: TimeThumb(
                          position: position,
                          knobX: knobX - thumbX,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TimeThumb.height - 21),
            ],
          ),
        );
      },
    );
  }
}

/// 진행 막대 손잡이: 원형 손잡이 아래로 둥근 삼각형이 이어지고, 그 아래 현재 재생 시간 상자.
/// 손잡이 원의 가운데가 가로 [knobX] (왼쪽 위 모서리 기준), 세로 [knobR]에 놓인다.
class TimeThumb extends StatelessWidget {
  const TimeThumb({super.key, required this.position, required this.knobX});

  final Duration position;
  final double knobX;

  static const width = 52.0;
  static const height = 40.0;
  static const knobR = 7.0;

  /// 손잡이가 막대 끝에 가도 상자가 밀리지 않도록 막대 양끝에 두는 여백.
  static const edge = width / 2 - knobR;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ThumbPainter(
                  color: p.onSurface,
                  shadow: p.scrim.withValues(alpha: .3),
                  knobX: knobX,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 22,
              child: Center(
                child: Text(
                  TimeText.clock(position),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: p.background,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter({
    required this.color,
    required this.shadow,
    required this.knobX,
  });

  final Color color;
  final Color shadow;
  final double knobX;

  @override
  void paint(Canvas canvas, Size size) {
    const r = TimeThumb.knobR;
    final x = knobX;
    final l = (x - 7).clamp(2.0, size.width);
    final rt = (x + 7).clamp(0.0, size.width - 2);
    final body = RRect.fromLTRBR(
      0,
      size.height - 22,
      size.width,
      size.height,
      const Radius.circular(11),
    );
    final base = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, r), radius: r))
      ..addRRect(body);
    final neck = Path()
      ..moveTo(x, r + 2)
      ..lineTo(rt, body.top + 1)
      ..lineTo(l, body.top + 1)
      ..close();
    final all = Path.combine(PathOperation.union, base, neck);
    canvas.drawPath(
      all,
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(all, Paint()..color = color);
    // 삼각형 모서리를 둥글게.
    canvas.drawPath(
      neck,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.color != color || old.knobX != knobX || old.shadow != shadow;
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
          iconSize: 30,
          tooltip: on ? l10n.trackMenuUnfavorite : l10n.trackMenuFavorite,
          onPressed: () => cubit.toggleFavorite(trackId),
          icon: Icon(
            on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 30,
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
/// 1) 제목 · 아티스트 + 가사/커버 · 현재 재생목록(대기열) · 좋아요
/// 2) 진행 막대 (총 시간은 위, 현재 시간은 손잡이 아래 둥근 삼각형 상자)
/// 3) 10초 뒤로 · 이전 · 재생 · 다음 · 10초 앞으로
/// 4) 셔플 · 반복 (왼쪽), 수면 타이머 · 이퀄라이저 (오른쪽)
///
/// [seekBar]가 false면 진행 막대는 커버 쪽(호, [MorphSeek])에 있어 2번 줄은 없다.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.data,
    required this.play,
    this.seekBar = true,
  });

  final PlayerLayoutData data;
  final Widget play;
  final bool seekBar;

  @override
  Widget build(BuildContext context) {
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
                    const QueueButton(),
                    PlayerLikeButton(trackId: data.track.id),
                  ],
                ),
              ),
            ],
          ),
          if (seekBar) ...[
            const SizedBox(height: AppSpacing.xs),
            PlayerSeekBar(
              progress: data.state.progress,
              onSeek: data.vm.seekFraction,
              onSeekStart: data.vm.beginScrub,
              onSeekEnd: data.vm.endScrub,
              position: data.state.position,
              total: data.track.duration,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SeekStepButton(data: data, forward: false),
              SkipButton(data: data, next: false),
              play,
              SkipButton(data: data, next: true),
              SeekStepButton(data: data, forward: true),
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
            ],
          ),
        ],
      ),
    );
  }
}

/// 모양 윤곽을 그리는 길. [extend]는 영역 위로 늘린 높이 (화면 맨 위까지 잇는 용도).
typedef SeekPathBuilder = Path Function(Size size, double extend);

/// 진행 막대가 모양(호 · 틀)을 따라 돌다가, 가사 보기에서는 곧은 막대로 부드럽게 펴진다.
///
/// [straight]가 켜지면 윤곽 위의 점들이 영역 아래쪽의 곧은 막대로 옮겨 가고, 커버는 흐려지고
/// 가사가 나타난다. [reachTop]이면 영역 위로 화면 맨 위까지 늘려서 그린다.
class MorphSeek extends StatefulWidget {
  const MorphSeek({
    super.key,
    required this.progress,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    required this.straight,
    required this.pathOf,
    required this.cover,
    required this.lyrics,
    required this.track,
    required this.fill,
    this.knobRing,
    required this.position,
    required this.total,
    required this.timeAt,
    this.reachTop = false,
  });

  final double progress;
  final ValueChanged<double> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final bool straight;
  final SeekPathBuilder pathOf;

  /// 커버 모양 (늘린 영역 전체에 깔린다).
  final Widget Function(Size size, double extend) cover;
  final Widget lyrics;
  final Color track;
  final Color fill;
  final Color? knobRing;
  final bool reachTop;

  /// 현재 · 전체 재생 시간.
  final Duration position;
  final Duration total;

  /// 곡선 모양일 때 현재 · 전체 시간을 양옆에 놓을 가운데 위치 (모양 아래 뚫린 곳).
  final Offset Function(Size size, double extend) timeAt;

  /// 곧은 막대가 놓이는 아래 띠 높이.
  static const band = 64.0;
  static const _samples = 200;

  /// [points] 중 [local]에서 가장 가까운 점의 위치(0 ~ 1)와 거리.
  static (double, double) nearest(List<Offset> points, Offset local) {
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final d = (points[i] - local).distance;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return (best / (points.length - 1), bestDist);
  }

  @override
  State<MorphSeek> createState() => _MorphSeekState();
}

class _MorphSeekState extends State<MorphSeek>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    value: widget.straight ? 1 : 0,
  );
  var _extend = 0.0;
  var _dragging = false;
  var _points = const <Offset>[];

  @override
  void didUpdateWidget(MorphSeek old) {
    super.didUpdateWidget(old);
    if (old.straight != widget.straight) {
      widget.straight ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _measure() {
    if (!widget.reachTop) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final dy = box.localToGlobal(Offset.zero).dy.clamp(0.0, 400.0);
    if ((dy - _extend).abs() > .5) setState(() => _extend = dy);
  }

  List<Offset> _pointsFor(Size size, double t) {
    final metric = widget.pathOf(size, _extend).computeMetrics().first;
    final y = size.height - MorphSeek.band + 24;
    const inset = AppSpacing.lg + TimeThumb.edge + TimeThumb.knobR;
    const n = MorphSeek._samples;
    return [
      for (var i = 0; i <= n; i++)
        Offset.lerp(
          metric.getTangentForOffset(metric.length * i / n)!.position,
          Offset(inset + (size.width - inset * 2) * i / n, y),
          t,
        )!,
    ];
  }

  bool _near(Offset local, double t) {
    final (_, dist) = MorphSeek.nearest(_points, local);
    return dist <= 44 - 16 * t;
  }

  void _endDrag() {
    if (_dragging) widget.onSeekEnd?.call();
    _dragging = false;
  }

  void _seek(Offset local) =>
      widget.onSeek(MorphSeek.nearest(_points, local).$1);

  /// 곡선일 때는 모양 아래 뚫린 곳 양옆에 현재(왼쪽) · 전체(오른쪽) 시간, 곧은 막대일 때는 막대 위 총 시간과
  /// 손잡이 아래 삼각형 + 현재 시간.
  List<Widget> _timeLabels(BuildContext context, Size size, double t) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: p.onSurface.withValues(alpha: .7));
    const w = 72.0;
    final gap = widget.timeAt(size, _extend);
    final v = widget.progress.clamp(0.0, 1.0);
    final head = _points.isEmpty
        ? Offset.zero
        : _points[(v * (_points.length - 1)).round()];
    final lineY = size.height - MorphSeek.band + 24;
    final thumbX = head.dx - TimeThumb.width / 2;
    return [
      if (t < 1) ...[
        Positioned(
          left: gap.dx - 76 - w,
          top: gap.dy - 10,
          width: w,
          child: IgnorePointer(
            child: Opacity(
              opacity: 1 - t,
              child: Text(
                TimeText.clock(widget.position),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
        Positioned(
          left: gap.dx + 76,
          top: gap.dy - 10,
          width: w,
          child: IgnorePointer(
            child: Opacity(
              opacity: 1 - t,
              child: Text(
                TimeText.clock(widget.total),
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      ],
      if (t > 0) ...[
        Positioned(
          right: AppSpacing.lg,
          top: lineY - 24,
          child: Opacity(
            opacity: t,
            child: Text(TimeText.clock(widget.total), style: style),
          ),
        ),
        Positioned(
          left: thumbX,
          top: lineY - TimeThumb.knobR,
          child: Opacity(
            opacity: t,
            child: TimeThumb(
              position: widget.position,
              knobX: head.dx - thumbX,
            ),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    final p = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -_extend,
          left: 0,
          right: 0,
          bottom: 0,
          child: LayoutBuilder(
            builder: (context, c) {
              final size = c.biggest;
              return AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = Curves.easeInOutCubic.transform(_c.value);
                  _points = _pointsFor(size, t);
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) {
                      _dragging = _near(e.localPosition, t);
                      if (_dragging) {
                        widget.onSeekStart?.call();
                        _seek(e.localPosition);
                      }
                    },
                    onPointerMove: (e) {
                      if (_dragging) _seek(e.localPosition);
                    },
                    onPointerUp: (_) => _endDrag(),
                    onPointerCancel: (_) => _endDrag(),
                    child: Stack(
                      children: [
                        if (t < 1)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 1 - t,
                                child: widget.cover(size, _extend),
                              ),
                            ),
                          ),
                        if (t > 0)
                          Positioned(
                            top: _extend,
                            left: 0,
                            right: 0,
                            bottom: MorphSeek.band,
                            child: IgnorePointer(
                              ignoring: t < 1,
                              child: Opacity(opacity: t, child: widget.lyrics),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _MorphPainter(
                                points: _points,
                                value: widget.progress,
                                t: t,
                                track: Color.lerp(
                                  widget.track,
                                  p.onSurface.withValues(alpha: .2),
                                  t,
                                )!,
                                fill: Color.lerp(widget.fill, p.onSurface, t)!,
                                knobRing: widget.knobRing,
                                shadow: p.scrim.withValues(alpha: .4),
                              ),
                            ),
                          ),
                        ),
                        ..._timeLabels(context, size, t),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter({
    required this.points,
    required this.value,
    required this.t,
    required this.track,
    required this.fill,
    required this.knobRing,
    required this.shadow,
  });

  final List<Offset> points;
  final double value;
  final double t;
  final Color track;
  final Color fill;
  final Color? knobRing;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..addPolygon(points, false), line..color = track);
    final v = value.clamp(0.0, 1.0) * (points.length - 1);
    final whole = v.floor();
    final head = whole >= points.length - 1
        ? points.last
        : Offset.lerp(points[whole], points[whole + 1], v - whole)!;
    if (v > 0) {
      canvas.drawPath(
        Path()..addPolygon([...points.take(whole + 1), head], false),
        line..color = fill,
      );
    }
    final r = 8 - t;
    final ring = knobRing;
    if (ring != null) canvas.drawCircle(head, r + 3, Paint()..color = ring);
    canvas.drawCircle(
      head,
      r,
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(head, r, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_MorphPainter old) =>
      old.points != points ||
      old.value != value ||
      old.t != t ||
      old.track != track ||
      old.fill != fill;
}
