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
    final strength = blurred ? .75 : .5;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.background),
        if (image != null) ...[
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
            child: Image(image: image, fit: BoxFit.cover),
          ),
          ColoredBox(color: p.background.withValues(alpha: .62)),
        ] else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  art.glow[1].withValues(alpha: strength),
                  art.glow[2].withValues(alpha: strength * .35),
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
              onPressed: () => showTrackMenu(btn, track),
            )
          : IconButton(
              tooltip: l10n.trackMenuTitle,
              onPressed: () => showTrackMenu(btn, track),
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
  const PlayerTitle({super.key, required this.track, this.center = false});

  final Track track;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          track.title,
          style: text.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          [
            track.artist.isEmpty ? l10n.unknownArtist : track.artist,
            if (track.album.isNotEmpty) track.album,
          ].join(' · '),
          style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.start,
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

/// 누르거나 끌어서 위치를 옮기는 가는 진행 막대.
class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    required this.progress,
    required this.onSeek,
  });

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
            child: ProgressLine(value: progress, height: 3),
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
        ?.copyWith(color: context.palette.onSurfaceMuted);
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

/// "1:23 / 3:45" 알약.
class TimePill extends StatelessWidget {
  const TimePill({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: p.onSurface.withValues(alpha: .1),
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 1,
        ),
        child: Text(
          '${formatDuration(data.state.position)} / '
          '${formatDuration(data.track.duration)}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
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
  const SkipButton({super.key, required this.data, required this.next});

  final PlayerLayoutData data;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      iconSize: 36,
      tooltip: next ? l10n.actionNext : l10n.actionPrevious,
      onPressed: next ? data.vm.next : data.vm.previous,
      icon: Icon(
        next ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
        color: context.palette.onSurface,
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

/// 재생 줄: 셔플 · 이전 · 재생 · 다음 · 반복.
class PlayerTransport extends StatelessWidget {
  const PlayerTransport({super.key, required this.data, required this.play});

  final PlayerLayoutData data;
  final Widget play;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      ShuffleButton(data: data),
      SkipButton(data: data, next: false),
      play,
      SkipButton(data: data, next: true),
      RepeatButton(data: data),
    ],
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

/// 가는 원형 진행 호 (12시 방향에서 시계 방향) + 끝의 점.
class ThinRingPainter extends CustomPainter {
  ThinRingPainter({
    required this.value,
    required this.track,
    required this.fill,
    this.stroke = 3,
  });

  final double value;
  final Color track;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke * 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, line..color = track);
    final v = value.clamp(0.0, 1.0);
    if (v <= 0) return;
    final sweep = 2 * math.pi * v;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      line
        ..color = fill.withValues(alpha: .5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 1.5),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      line
        ..color = fill
        ..maskFilter = null,
    );
    final end = center + Offset.fromDirection(-math.pi / 2 + sweep, radius);
    canvas.drawCircle(end, stroke * 1.9, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(ThinRingPainter old) =>
      old.value != value || old.track != track || old.fill != fill;
}
