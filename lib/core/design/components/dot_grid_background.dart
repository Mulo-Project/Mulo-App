import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 검정 배경 + 옅은 점 격자. 화면 최상단 배경으로 쓴다.
class DotGridBackground extends StatelessWidget {
  const DotGridBackground({super.key, this.spacing = 16, this.child});

  final double spacing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.background,
      child: CustomPaint(
        painter: _DotGridPainter(color: p.dotGrid, spacing: spacing),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) =>
      old.color != color || old.spacing != spacing;
}
