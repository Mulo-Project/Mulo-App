import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import 'player_common.dart';

/// 플레이어 모양 4가지 (카드 · 상자 없이 배경 위에 바로 놓는다).
/// 위쪽(커버 · 진행 표시)만 다르고, 하단 조작부는 모두 [PlayerControls] 하나를 쓴다.

const _side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

/// 가사 보기일 때 커버 자리를 채우는 가사.
Widget _lyrics(PlayerLayoutData data) => Padding(
  padding: _side,
  child: PlayerLyricsPane(track: data.track),
);

/// 네모: 큰 정사각 커버, 아래 진행 막대.
class SquarePlayer extends StatelessWidget {
  const SquarePlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    return PlayerBackdrop(
      art: art,
      child: SafeArea(
        child: Column(
          children: [
            PlayerTopBar(track: data.track),
            Expanded(
              child: data.showLyrics
                  ? _lyrics(data)
                  : Padding(
                      padding: _side,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
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
            ),
            const SizedBox(height: AppSpacing.sm),
            PlayerControls(
              data: data,
              play: SolidPlayButton(data: data, size: 72),
            ),
            const SizedBox(height: AppSpacing.xs),
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
                  PlayerControls(
                    data: data,
                    play: SolidPlayButton(data: data, size: 72),
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
              child: data.showLyrics
                  ? _lyrics(data)
                  : Padding(
                      padding: _side,
                      child: LayoutBuilder(
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
            PlayerControls(
              data: data,
              play: GlowPlayButton(data: data, size: 72),
              seekBar: false,
            ),
            const SizedBox(height: AppSpacing.xs),
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
        ],
      ),
    );
  }
}

/// 커스텀: 소프트(뉴모피즘) 화면. 키 큰 둥근 틀 안에 커버, 진행 막대가 틀을 따라 돈다.
class CustomPlayer extends StatelessWidget {
  const CustomPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    final l10n = context.l10n;
    return ColoredBox(
      color: p.surface,
      child: SafeArea(
        child: Column(
          children: [
            PlayerTopBar(track: data.track),
            Expanded(
              child: data.showLyrics
                  ? _lyrics(data)
                  : LayoutBuilder(
                      builder: (context, c) {
                        final w = math.min(c.maxWidth * .78, c.maxHeight / 1.2);
                        return Center(
                          child: _CapsuleCover(
                            data: data,
                            art: art,
                            width: w,
                            height: w * 1.2,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PlayerControls(
              data: data,
              seekBar: false,
              neu: true,
              play: NeuCircle(
                size: 76,
                child: SizedBox.square(
                  dimension: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accent,
                    ),
                    child: IconButton(
                      tooltip: data.state.isPlaying
                          ? l10n.actionPause
                          : l10n.actionPlay,
                      onPressed: data.vm.togglePlay,
                      icon: Icon(
                        data.state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 32,
                        color: p.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// 둥근 틀 윤곽을 위쪽 가운데에서 시계 방향으로 한 바퀴 도는 길.
Path _capsulePath(Size s, double inset) {
  final r = s.width / 2 - inset;
  final cx = s.width / 2;
  final top = inset;
  final bottom = s.height - inset;
  final upper = Rect.fromCircle(center: Offset(cx, top + r), radius: r);
  final lower = Rect.fromCircle(center: Offset(cx, bottom - r), radius: r);
  return Path()
    ..moveTo(cx, top)
    ..arcTo(upper, -math.pi / 2, math.pi / 2, false)
    ..lineTo(cx + r, bottom - r)
    ..arcTo(lower, 0, math.pi, false)
    ..lineTo(cx - r, top + r)
    ..arcTo(upper, math.pi, math.pi / 2, false);
}

/// 틀을 따라가는 진행 막대 + 끝의 둥근 손잡이.
class _CapsuleProgressPainter extends CustomPainter {
  _CapsuleProgressPainter({
    required this.value,
    required this.inset,
    required this.track,
    required this.fill,
    required this.knobRing,
  });

  final double value;
  final double inset;
  final Color track;
  final Color fill;
  final Color knobRing;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _capsulePath(size, inset);
    final metric = path.computeMetrics().first;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line..color = track);
    final v = value.clamp(0.0, 1.0);
    if (v > 0) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * v),
        line..color = fill,
      );
    }
    final t = metric.getTangentForOffset(metric.length * v);
    if (t != null) {
      canvas.drawCircle(t.position, 9, Paint()..color = knobRing);
      canvas.drawCircle(t.position, 6, Paint()..color = fill);
    }
  }

  @override
  bool shouldRepaint(_CapsuleProgressPainter old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.knobRing != knobRing;
}

class _CapsuleCover extends StatelessWidget {
  const _CapsuleCover({
    required this.data,
    required this.art,
    required this.width,
    required this.height,
  });

  final PlayerLayoutData data;
  final PlayerArt art;
  final double width;
  final double height;

  static const _inset = 12.0;

  /// 틀 위 [local]에서 가장 가까운 곳의 위치(0 ~ 1).
  double _fractionAt(Offset local) {
    final metric = _capsulePath(
      Size(width, height),
      _inset,
    ).computeMetrics().first;
    var best = 0.0;
    var bestDist = double.infinity;
    const steps = 240;
    for (var i = 0; i <= steps; i++) {
      final t = metric.getTangentForOffset(metric.length * i / steps);
      if (t == null) continue;
      final d = (t.position - local).distanceSquared;
      if (d < bestDist) {
        bestDist = d;
        best = i / steps;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pad = _inset + 12;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => data.vm.seekFraction(_fractionAt(d.localPosition)),
      onPanUpdate: (d) => data.vm.seekFraction(_fractionAt(d.localPosition)),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width / 2),
            color: p.surface,
            boxShadow: neuShadows(context, depth: 10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.all(pad),
                child: PlayerCover(art: art, radius: width / 2 - pad),
              ),
              CustomPaint(
                painter: _CapsuleProgressPainter(
                  value: data.state.progress,
                  inset: _inset,
                  track: p.onSurface.withValues(alpha: .12),
                  fill: p.accent,
                  knobRing: p.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
