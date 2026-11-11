import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 원형 진행 표시: 옅은 유리 트랙 위에 강조 색 호 + 은은한 빛.
/// 가운데에 [child]를 둔다 (보통 [StatNumber]).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 160,
    this.stroke = 8,
    this.sweep = math.pi * 1.5,
    this.child,
  });

  /// 0 ~ 1.
  final double value;
  final double size;
  final double stroke;

  /// 호 전체 각도 (라디안). 기본 270°, 아래쪽이 열린 모양.
  final double sweep;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(
          value: v,
          stroke: stroke,
          sweep: sweep,
          track: p.glassBorder,
          fill: p.accent,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.sweep,
    required this.track,
    required this.fill,
  });

  final double value;
  final double stroke;
  final double sweep;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke,
    );
    final start = math.pi / 2 + (2 * math.pi - sweep) / 2;
    Paint line(Color c, {double blur = 0}) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = c
      ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;

    canvas.drawArc(rect, start, sweep, false, line(track));
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      start,
      sweep * value,
      false,
      line(fill.withValues(alpha: .6), blur: stroke),
    );
    canvas.drawArc(rect, start, sweep * value, false, line(fill));
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.sweep != sweep ||
      old.stroke != stroke;
}

/// 가로 진행 막대: 유리 트랙 + 강조 색 채움 + 끝에 은은한 빛.
class ProgressLine extends StatelessWidget {
  const ProgressLine({
    super.key,
    required this.value,
    this.height = 4,
    this.buffered = 0,
  });

  final double value;
  final double height;

  /// 미리 받아 둔 비율 0 ~ 1. 트랙 위에 연하게 깔린다 (0이면 그리지 않는다).
  final double buffered;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: p.glassBorder,
                shape: const StadiumBorder(),
              ),
            ),
          ),
          if (buffered > 0)
            FractionallySizedBox(
              widthFactor: buffered.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: p.onSurface.withValues(alpha: .35),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: p.accent,
                shape: const StadiumBorder(),
                shadows: [
                  BoxShadow(
                    color: p.accent.withValues(alpha: .55),
                    blurRadius: height * 2.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 작은 원형 진행 표시: 얇은 트랙 위를 강조 색 호가 맨 위에서부터 시계 방향으로 채운다.
/// 가운데에 [child]를 둔다 (보통 남은 초). 버튼 안에 들어가는 크기용.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.value,
    this.size = 32,
    this.stroke = 2.5,
    this.child,
  });

  /// 0 ~ 1.
  final double value;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      size: Size.square(size),
      painter: _CountdownPainter(
        value: value.clamp(0.0, 1.0),
        stroke: stroke,
        track: p.glassBorder,
        fill: p.accent,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: child),
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  _CountdownPainter({
    required this.value,
    required this.stroke,
    required this.track,
    required this.fill,
  });

  final double value;
  final double stroke;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    Paint line(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = c;
    canvas.drawArc(rect, 0, 2 * math.pi, false, line(track));
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        line(fill),
      );
    }
  }

  @override
  bool shouldRepaint(_CountdownPainter old) =>
      old.value != value ||
      old.stroke != stroke ||
      old.track != track ||
      old.fill != fill;
}
