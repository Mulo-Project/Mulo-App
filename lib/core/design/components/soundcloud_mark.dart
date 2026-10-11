import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';

/// 사운드클라우드 아이콘: 주황 둥근 사각형 위에 막대(소리 파형)와 구름.
/// 비율은 공식 앱 아이콘(447 단위 기준)을 따른다.
class SoundcloudMark extends StatelessWidget {
  const SoundcloudMark({super.key, this.size = 24});

  /// 사각형 한 변.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('soundcloud-mark'),
      dimension: size,
      child: CustomPaint(painter: _SoundcloudMarkPainter()),
    );
  }
}

class _SoundcloudMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 447;
    Rect r(double l, double t, double rt, double b) =>
        Rect.fromLTRB(l * k, t * k, rt * k, b * k);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * .22),
      ),
      Paint()..color = AppPalette.soundcloudOrange,
    );

    final ink = Paint()..color = AppPalette.soundcloudInk;
    // 막대 7개: (가운데 x, 위, 아래)
    const bars = <(double, double, double)>[
      (56, 230, 285),
      (80, 217, 298),
      (104, 220, 302),
      (129, 195, 302),
      (153, 184, 302),
      (177, 187, 302),
      (201, 173, 302),
    ];
    for (final (x, top, bottom) in bars) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r(x - 6, top, x + 6, bottom),
          Radius.circular(6 * k),
        ),
        ink,
      );
    }

    // 구름: 왼쪽 큰 둥근 지붕 + 오른쪽 작은 혹.
    final cloud = Path()
      ..moveTo(220 * k, 302 * k)
      ..lineTo(220 * k, 170 * k)
      ..arcToPoint(Offset(338 * k, 213 * k), radius: Radius.circular(70 * k))
      ..arcToPoint(
        Offset(338 * k, 302 * k),
        radius: Radius.circular(44 * k),
        clockwise: true,
      )
      ..close();
    canvas
      ..drawPath(cloud, ink)
      ..drawCircle(Offset(354 * k, 258 * k), 44 * k, ink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
