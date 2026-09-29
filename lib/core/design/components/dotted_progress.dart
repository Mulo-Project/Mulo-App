import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 점선 원호 진행 표시 (레퍼런스의 얇은 점선 호).
///
/// [sweep] 만큼의 호를 점으로 그리고, [value] 비율만큼 강조 색으로 채운다.
/// 가운데에 [child]를 둔다 (보통 [DotMatrixText]).
class DottedProgressArc extends StatelessWidget {
  const DottedProgressArc({
    super.key,
    required this.value,
    this.size = 180,
    this.dotCount = 48,
    this.dotRadius = 2.2,
    this.sweep = math.pi * 1.5,
    this.child,
  });

  /// 0 ~ 1.
  final double value;
  final double size;
  final int dotCount;
  final double dotRadius;

  /// 호 전체 각도 (라디안). 기본 270°, 아래쪽이 열린 모양.
  final double sweep;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(
        size: Size.square(size),
        painter: _ArcPainter(
          value: v,
          dotCount: dotCount,
          dotRadius: dotRadius,
          sweep: sweep,
          track: p.onSurface.withValues(alpha: .18),
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

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.value,
    required this.dotCount,
    required this.dotRadius,
    required this.sweep,
    required this.track,
    required this.fill,
  });

  final double value;
  final int dotCount;
  final double dotRadius;
  final double sweep;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - dotRadius * 2;
    // 아래 가운데를 비우고 대칭이 되도록 시작 각을 잡는다.
    final start = math.pi / 2 + (2 * math.pi - sweep) / 2;
    final filled = (value * dotCount).round();
    final trackPaint = Paint()..color = track;
    final fillPaint = Paint()..color = fill;

    for (var i = 0; i < dotCount; i++) {
      final a = start + sweep * i / (dotCount - 1);
      final pos = center + Offset(math.cos(a), math.sin(a)) * radius;
      final on = i < filled;
      canvas.drawCircle(
        pos,
        on ? dotRadius * 1.25 : dotRadius,
        on ? fillPaint : trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.dotCount != dotCount ||
      old.sweep != sweep;
}

/// 점선 가로 진행 막대 (미니 플레이어 · 다운로드 진행).
class DottedProgressBar extends StatelessWidget {
  const DottedProgressBar({
    super.key,
    required this.value,
    this.height = 4,
    this.spacing = 7,
  });

  final double value;
  final double height;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          value: value.clamp(0, 1),
          dot: height,
          spacing: spacing,
          track: p.onSurface.withValues(alpha: .18),
          fill: p.accent,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.value,
    required this.dot,
    required this.spacing,
    required this.track,
    required this.fill,
  });

  final double value;
  final double dot;
  final double spacing;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final count = (size.width / spacing).floor();
    if (count <= 0) return;
    final filled = (value * count).round();
    final r = dot / 2;
    final trackPaint = Paint()..color = track;
    final fillPaint = Paint()..color = fill;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(i * spacing + r, size.height / 2),
        r,
        i < filled ? fillPaint : trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.value != value || old.track != track || old.fill != fill;
}
