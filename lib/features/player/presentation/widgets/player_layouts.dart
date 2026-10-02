import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import 'player_common.dart';

/// 플레이어 모양 4가지 (카드 · 상자 없이 배경 위에 바로 놓는다).
/// 모두 같은 [PlayerLayoutData]를 받아 배치만 다르게 한다.

const _side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

/// 음반: 둥근 디스크 커버 + 둘레의 가는 진행 호, 곡 정보는 디스크 위.
class VinylPlayer extends StatelessWidget {
  const VinylPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    return PlayerBackdrop(
      art: art,
      child: SafeArea(
        child: Column(
          children: [
            PlayerTopBar(track: data.track),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: TimePill(data: data),
            ),
            Expanded(
              child: Padding(
                padding: _side,
                child: data.showLyrics
                    ? PlayerLyricsPane(track: data.track)
                    : Center(
                        child: _Disc(data: data, art: art),
                      ),
              ),
            ),
            Padding(
              padding: _side,
              child: PlayerTransport(
                data: data,
                play: SolidPlayButton(data: data),
              ),
            ),
            Padding(
              padding: _side,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PlayerLikeButton(trackId: data.track.id),
                  LyricsToggleButton(data: data),
                  const QueueButton(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.data, required this.art});

  final PlayerLayoutData data;
  final PlayerArt art;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth, c.maxHeight);
        final inset = size * .06;
        final label = size * .46;
        return RingSeek(
          size: size,
          start: -math.pi / 2,
          sweep: 2 * math.pi,
          inner: .86,
          onSeek: data.vm.seekFraction,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: ThinRingPainter(
                    value: data.state.progress,
                    track: p.onSurface.withValues(alpha: .14),
                    fill: p.accent,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(inset),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: PlayerCover(art: art, radius: size, icon: false),
                    ),
                    // 음반 홈.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GroovesPainter(
                          color: p.scrim.withValues(alpha: .16),
                        ),
                      ),
                    ),
                    // 가운데 라벨: 곡 정보.
                    Center(
                      child: Container(
                        width: label,
                        height: label,
                        padding: EdgeInsets.all(label * .12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.scrim.withValues(alpha: .58),
                        ),
                        child: onGlow(
                          context,
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                data.track.title,
                                style: text.titleSmall,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                data.track.artist.isEmpty
                                    ? context.l10n.unknownArtist
                                    : data.track.artist,
                                style: text.labelSmall,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroovesPainter extends CustomPainter {
  _GroovesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = color;
    for (var r = radius * .56; r < radius; r += 5) {
      canvas.drawCircle(center, r, line);
    }
  }

  @override
  bool shouldRepaint(_GroovesPainter old) => old.color != color;
}

/// 네모: 큰 정사각 커버, 제목 · 하트 · 더 보기, 가는 진행 막대 + ±10초.
class SquarePlayer extends StatelessWidget {
  const SquarePlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final l10n = context.l10n;
    final p = context.palette;
    final vm = data.vm;
    return PlayerBackdrop(
      art: art,
      child: SafeArea(
        child: Column(
          children: [
            PlayerTopBar(track: data.track, showMore: false),
            Expanded(
              child: Padding(
                padding: _side,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: data.showLyrics
                          ? PlayerLyricsPane(track: data.track)
                          : Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Hero(
                                  tag: 'now-playing',
                                  child: PlayerCover(art: art),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: PlayerTitle(track: data.track)),
                        PlayerLikeButton(trackId: data.track.id),
                        PlayerMoreButton(track: data.track, circle: false),
                      ],
                    ),
                    PlayerSeekBar(
                      progress: data.state.progress,
                      onSeek: vm.seekFraction,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: l10n.playerRewind10,
                          onPressed: () => vm.seekTo(
                            data.state.position - const Duration(seconds: 10),
                          ),
                          icon: Icon(
                            Icons.replay_10_rounded,
                            color: p.onSurfaceMuted,
                          ),
                        ),
                        TimePill(data: data),
                        IconButton(
                          tooltip: l10n.playerForward10,
                          onPressed: () => vm.seekTo(
                            data.state.position + const Duration(seconds: 10),
                          ),
                          icon: Icon(
                            Icons.forward_10_rounded,
                            color: p.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PlayerTransport(
                      data: data,
                      play: SolidPlayButton(data: data),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LyricsToggleButton(data: data),
                        const QueueButton(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 꽉 찬 이미지: 커버가 위쪽을 채우고 배경으로 스며든다.
class FullBleedPlayer extends StatelessWidget {
  const FullBleedPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    final vm = data.vm;
    return ColoredBox(
      color: p.background,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: c.maxHeight * .62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlayerCover(art: art, radius: 0),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          p.background.withValues(alpha: 0),
                          p.background.withValues(alpha: 0),
                          p.background,
                        ],
                        stops: const [0, .5, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  PlayerTopBar(track: data.track),
                  Expanded(
                    child: data.showLyrics
                        ? Padding(
                            padding: _side,
                            child: ColoredBox(
                              color: p.background.withValues(alpha: .86),
                              child: PlayerLyricsPane(track: data.track),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Padding(
                    padding: _side,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: PlayerTitle(track: data.track)),
                            PlayerLikeButton(trackId: data.track.id),
                          ],
                        ),
                        PlayerSeekBar(
                          progress: data.state.progress,
                          onSeek: vm.seekFraction,
                        ),
                        PlayerTimes(data: data),
                        const SizedBox(height: AppSpacing.xs),
                        PlayerTransport(
                          data: data,
                          play: SolidPlayButton(data: data),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LyricsToggleButton(data: data),
                            const QueueButton(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 호: 흐린 커버 배경, 빛나는 재생 버튼을 두른 곡선 진행 호.
class ArcPlayer extends StatelessWidget {
  const ArcPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  static const _sweep = math.pi * 1.5;
  static const _start = math.pi / 2 + (2 * math.pi - _sweep) / 2;
  static const _ring = 208.0;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final vm = data.vm;
    return PlayerBackdrop(
      art: art,
      blurred: true,
      child: SafeArea(
        child: Column(
          children: [
            PlayerTopBar(track: data.track),
            Expanded(
              child: Padding(
                padding: _side,
                child: data.showLyrics
                    ? PlayerLyricsPane(track: data.track)
                    : LayoutBuilder(
                        builder: (context, c) {
                          final size = math.min(
                            math.min(c.maxWidth * .62, c.maxHeight),
                            280.0,
                          );
                          return Center(
                            child: SizedBox.square(
                              dimension: size,
                              child: PlayerCover(art: art, radius: size),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: _side,
              child: PlayerTitle(track: data.track, center: true),
            ),
            const SizedBox(height: AppSpacing.xs),
            TimePill(data: data),
            RingSeek(
              size: _ring,
              start: _start,
              sweep: _sweep,
              inner: .74,
              onSeek: vm.seekFraction,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ProgressRing(
                    value: data.state.progress,
                    size: _ring,
                    stroke: 5,
                    sweep: _sweep,
                  ),
                  GlowPlayButton(data: data),
                  Positioned(
                    bottom: 6,
                    left: _ring / 2 - 60,
                    child: SkipButton(data: data, next: false),
                  ),
                  Positioned(
                    bottom: 6,
                    right: _ring / 2 - 60,
                    child: SkipButton(data: data, next: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: _side,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShuffleButton(data: data),
                  PlayerLikeButton(trackId: data.track.id),
                  LyricsToggleButton(data: data),
                  const QueueButton(),
                  RepeatButton(data: data),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}
