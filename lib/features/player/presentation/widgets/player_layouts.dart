import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import 'player_common.dart';

/// 플레이어 모양 4가지 (카드 · 상자 없이 배경 위에 바로 놓는다).
/// 모두 같은 [PlayerLayoutData]를 받아 배치만 다르게 한다.

const _side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

/// 재생 줄: 셔플 · 이전 · 재생 · 다음 · 반복.
Widget _transport(PlayerLayoutData data, Widget play) => Padding(
  padding: _side,
  child: PlayerTransport(data: data, play: play),
);

/// 음반: 둥근 디스크 커버 + 둘레의 가는 진행 호, 곡 정보는 디스크 위.
class VinylPlayer extends StatelessWidget {
  const VinylPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final l10n = context.l10n;
    return PlayerBackdrop(
      art: art,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xxs,
                  0,
                  0,
                ),
                child: CircleIconButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip: l10n.actionBack,
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  ShuffleButton(data: data),
                  Expanded(
                    child: PlayerTitle(
                      track: data.track,
                      center: true,
                      large: false,
                      withAlbum: false,
                    ),
                  ),
                  RepeatButton(data: data),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TimeText(data: data),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: data.showLyrics ? AppSpacing.lg : AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: data.showLyrics
                    ? PlayerLyricsPane(track: data.track)
                    : Center(
                        child: _Disc(data: data, art: art),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PlayerLikeButton(trackId: data.track.id),
                  AddToPlaylistButton(trackId: data.track.id),
                  SleepTimerButton(data: data),
                  PlayerMoreButton(track: data.track, circle: false),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SeekStepButton(data: data, forward: false),
                  SkipButton(data: data, next: false),
                  GlowPlayButton(data: data, size: 76),
                  SkipButton(data: data, next: true),
                  SeekStepButton(data: data, forward: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const EqualizerButton(),
                  LyricsLabelButton(data: data),
                  const QueueButton(),
                ],
              ),
            ),
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
        final label = size * .5;
        return RingSeek(
          size: size,
          start: -math.pi / 2,
          sweep: 2 * math.pi,
          inner: .9,
          onSeek: data.vm.seekFraction,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 음반 본체: 흐릿하게 어두운 커버 + 홈.
              Padding(
                padding: const EdgeInsets.all(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlayerCover(art: art, radius: size, icon: false),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.scrim.withValues(alpha: .5),
                      ),
                    ),
                    CustomPaint(
                      painter: _GroovesPainter(
                        color: p.onSurface.withValues(alpha: .07),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: ThinRingPainter(
                    value: data.state.progress,
                    track: p.onSurface.withValues(alpha: .2),
                    fill: p.onSurface,
                    shadow: p.scrim.withValues(alpha: .4),
                    stroke: 3,
                    knob: 7,
                  ),
                ),
              ),
              // 가운데 라벨: 커버 이미지 + 곡 정보.
              SizedBox.square(
                dimension: label,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlayerCover(art: art, radius: label, icon: false),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.scrim.withValues(alpha: .42),
                        border: Border.all(
                          color: p.onSurface.withValues(alpha: .18),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(label * .14),
                      child: onGlow(
                        context,
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data.track.title,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              data.track.artist.isEmpty
                                  ? context.l10n.unknownArtist
                                  : data.track.artist,
                              style: text.labelMedium,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
      ..strokeWidth = .8
      ..color = color;
    for (var r = radius * .52; r < radius - 2; r += 6) {
      canvas.drawCircle(center, r, line);
    }
  }

  @override
  bool shouldRepaint(_GroovesPainter old) => old.color != color;
}

/// 네모: 큰 정사각 커버, 제목 · 하트, 진행 막대, 재생 줄.
class SquarePlayer extends StatelessWidget {
  const SquarePlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    final vm = data.vm;
    return PlayerBackdrop(
      art: art,
      child: SafeArea(
        child: Column(
          children: [
            PlayerTopBar(track: data.track),
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
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.lg,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: p.scrim.withValues(alpha: .35),
                                        blurRadius: 40,
                                        offset: const Offset(0, 18),
                                      ),
                                    ],
                                  ),
                                  child: Hero(
                                    tag: 'now-playing',
                                    child: PlayerCover(art: art),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(child: PlayerTitle(track: data.track)),
                        PlayerLikeButton(trackId: data.track.id),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PlayerSeekBar(
                      progress: data.state.progress,
                      onSeek: vm.seekFraction,
                    ),
                    PlayerTimes(data: data),
                    const SizedBox(height: AppSpacing.sm),
                    PlayerTransport(
                      data: data,
                      play: SolidPlayButton(data: data, size: 72),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LyricsToggleButton(data: data),
                        SeekStepButton(data: data, forward: false),
                        SeekStepButton(data: data, forward: true),
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
              height: c.maxHeight * .66,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlayerCover(art: art, radius: 0),
                  // 위: 상단 버튼이 읽히게 살짝 어둡게, 아래: 배경으로 부드럽게.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          p.scrim.withValues(alpha: .35),
                          p.scrim.withValues(alpha: 0),
                          p.background.withValues(alpha: 0),
                          p.background.withValues(alpha: .45),
                          p.background.withValues(alpha: .85),
                          p.background,
                        ],
                        stops: const [0, .22, .45, .7, .88, 1],
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
                        const SizedBox(height: AppSpacing.xs),
                        PlayerSeekBar(
                          progress: data.state.progress,
                          onSeek: vm.seekFraction,
                        ),
                        PlayerTimes(data: data),
                        const SizedBox(height: AppSpacing.sm),
                        PlayerTransport(
                          data: data,
                          play: SolidPlayButton(data: data, size: 72),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 호: 흐린 커버 배경, 커버를 감싸는 곡선 진행 막대.
class ArcPlayer extends StatelessWidget {
  const ArcPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  /// 아래쪽이 열린 정도 (라디안).
  static const _gap = math.pi * 4 / 9;
  static const _sweep = 2 * math.pi - _gap;
  static const _start = math.pi / 2 + _gap / 2;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
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
                        builder: (context, c) => Center(
                          child: _ArcCover(
                            data: data,
                            art: art,
                            size: math.min(c.maxWidth, c.maxHeight),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: _side,
              child: PlayerTitle(track: data.track, center: true),
            ),
            const SizedBox(height: AppSpacing.md),
            _transport(data, GlowPlayButton(data: data, size: 72)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PlayerLikeButton(trackId: data.track.id),
                  LyricsToggleButton(data: data),
                  const QueueButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 커버 둘레를 도는 진행 호. 호를 누르거나 끌어서 위치를 옮긴다.
class _ArcCover extends StatelessWidget {
  const _ArcCover({required this.data, required this.art, required this.size});

  final PlayerLayoutData data;
  final PlayerArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: p.onSurface.withValues(alpha: .7));
    return RingSeek(
      size: size,
      start: ArcPlayer._start,
      sweep: ArcPlayer._sweep,
      inner: .88,
      onSeek: data.vm.seekFraction,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(size * .09),
            child: PlayerCover(art: art, radius: size),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: ThinRingPainter(
                value: data.state.progress,
                track: p.onSurface.withValues(alpha: .2),
                fill: p.onSurface,
                shadow: p.scrim.withValues(alpha: .4),
                stroke: 4,
                knob: 8,
                start: ArcPlayer._start,
                sweep: ArcPlayer._sweep,
              ),
            ),
          ),
          // 열린 아래쪽: 지난 시간 · 전체 시간.
          Positioned(
            bottom: size * .02,
            left: size * .26,
            right: size * .26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(TimeText.clock(data.state.position), style: text),
                Text(TimeText.clock(data.track.duration), style: text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
