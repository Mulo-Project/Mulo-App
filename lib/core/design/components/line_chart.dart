import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 꺾은선 그래프의 점 하나. [label]은 아래 축에 찍을 글자 (비우면 안 찍는다).
class LineChartPoint {
  const LineChartPoint(this.value, {this.label = ''});

  final double value;
  final String label;
}

/// 꺾은선 그래프 (홈의 재생 기록). 선 · 점은 accent, 눈금선은 outline.
/// 가장 큰 값은 위쪽 오른쪽에 숫자로 적는다.
class AppLineChart extends StatelessWidget {
  const AppLineChart({
    super.key,
    required this.points,
    this.height = 160,
    this.maxLabel,
  });

  final List<LineChartPoint> points;
  final double height;

  /// 가장 큰 값 옆에 적을 글자 (예: "12회").
  final String? maxLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme.labelSmall!;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          points: points,
          line: p.accent,
          grid: p.outline,
          labelStyle: text.copyWith(color: p.onSurfaceMuted),
          maxLabel: maxLabel,
          direction: Directionality.of(context),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.line,
    required this.grid,
    required this.labelStyle,
    required this.maxLabel,
    required this.direction,
  });

  final List<LineChartPoint> points;
  final Color line;
  final Color grid;
  final TextStyle labelStyle;
  final String? maxLabel;
  final TextDirection direction;

  TextPainter _text(String s) => TextPainter(
    text: TextSpan(text: s, style: labelStyle),
    textDirection: direction,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const axisHeight = 20.0;
    const pad = 8.0;
    final plot = Rect.fromLTRB(
      pad,
      16,
      size.width - pad,
      size.height - axisHeight,
    );
    final top = points.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final scale = top <= 0 ? 1.0 : top;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in const [0.0, .5, 1.0]) {
      final y = plot.bottom - plot.height * f;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    Offset at(int i) => Offset(
      points.length == 1
          ? plot.center.dx
          : plot.left + plot.width * i / (points.length - 1),
      plot.bottom - plot.height * (points[i].value / scale),
    );

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dot = Paint()..color = line;
    final dotRadius = points.length > 16 ? 2.0 : 3.5;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(at(i), dotRadius, dot);
    }

    // 아래 축 글자는 겹치지 않게 건너뛴다.
    var lastRight = -double.infinity;
    for (var i = 0; i < points.length; i++) {
      if (points[i].label.isEmpty) continue;
      final tp = _text(points[i].label);
      final x = (at(i).dx - tp.width / 2).clamp(0.0, size.width - tp.width);
      if (x < lastRight + 6) continue;
      tp.paint(canvas, Offset(x, size.height - tp.height));
      lastRight = x + tp.width;
    }

    if (maxLabel != null && top > 0) {
      final tp = _text(maxLabel!);
      tp.paint(canvas, Offset(size.width - tp.width, 0));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.points != points ||
      old.line != line ||
      old.grid != grid ||
      old.maxLabel != maxLabel;
}
