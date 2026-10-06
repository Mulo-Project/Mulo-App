import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';

/// 유튜브 표시: 꽉 찬 빨간 원 안에 흰 링, 링 안에 각진 흰 재생 삼각형 (YouTube Music 모양).
/// 테마와 상관없이 같은 색이고, 아이콘 글리프 대신 직접 그려서 어느 크기에서도 또렷하다.
class YoutubeMark extends StatelessWidget {
  const YoutubeMark({super.key, this.size = 24});

  /// 원의 지름.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('youtube-mark'),
      dimension: size,
      child: CustomPaint(painter: _YoutubeMarkPainter()),
    );
  }
}

class _YoutubeMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final d = size.shortestSide;
    final c = size.center(Offset.zero);

    canvas
      ..drawCircle(c, d / 2, Paint()..color = AppPalette.youtubeRed)
      // 흰 링: 지름 54%, 두께 2.5%, 안쪽도 빨강.
      ..drawCircle(
        c,
        d * .27,
        Paint()
          ..color = AppPalette.markWhite
          ..style = PaintingStyle.stroke
          ..strokeWidth = d * .025,
      );

    // 재생 삼각형: 폭 22% · 높이 26%, 모서리는 각지게. 시각적 중심을 위해 약간 오른쪽.
    final tw = d * .22;
    final th = d * .26;
    final left = c.dx - tw / 2 + d * .015;
    final top = c.dy - th / 2;
    canvas.drawPath(
      Path()
        ..moveTo(left, top)
        ..lineTo(left + tw, c.dy)
        ..lineTo(left, top + th)
        ..close(),
      Paint()..color = AppPalette.youtubeMarkWhite,
    );
  }

  @override
  bool shouldRepaint(_YoutubeMarkPainter oldDelegate) => false;
}
