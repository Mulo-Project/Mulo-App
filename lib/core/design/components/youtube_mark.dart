import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';

/// 유튜브 표시: 빨간 둥근 사각형 안에 둥근 흰 재생 삼각형 (테마와 상관없다).
/// 아이콘 글리프 대신 직접 그려서 어느 크기에서도 모서리가 또렷하다.
class YoutubeMark extends StatelessWidget {
  const YoutubeMark({super.key, this.size = 24});

  /// 가로 길이. 세로는 70%.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('youtube-mark'),
      width: size,
      height: size * .7,
      child: CustomPaint(painter: _YoutubeMarkPainter()),
    );
  }
}

class _YoutubeMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(h * .3)),
      Paint()..color = AppPalette.youtubeRed,
    );

    // 삼각형은 세로의 절반 높이. 무게중심이 가운데 오도록 약간 오른쪽으로 둔다.
    final th = h * .5;
    final tw = th * .88;
    final left = (w - tw) / 2 + tw * .08;
    final top = (h - th) / 2;
    final tri = Path()
      ..moveTo(left, top)
      ..lineTo(left + tw, top + th / 2)
      ..lineTo(left, top + th)
      ..close();
    final white = AppPalette.markWhite;
    // 같은 색 외곽선으로 세 꼭짓점을 둥글게 만든다.
    canvas
      ..drawPath(
        tri,
        Paint()
          ..color = white
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .08
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(tri, Paint()..color = white);
  }

  @override
  bool shouldRepaint(_YoutubeMarkPainter oldDelegate) => false;
}
