import 'dart:ui' as ui;

import '../../features/covers/domain/entities/cover_art.dart';

/// 그림이 덮지 못한 곳의 색 (검정).
const coverEmptyColor = ui.Color(0xFF000000);

/// [image]를 [transform]대로 정사각형 [side] 칸에 그린다: 검정 바탕 위에 이동 · 확대 · 회전.
/// 목록 · 카드 · 파일 태그의 커버가 모두 이 한 곳의 규칙을 쓴다. 칸 밖은 잘린다.
void paintCover(
  ui.Canvas canvas,
  double side,
  ui.Image image,
  CoverTransform transform,
) {
  final frame = ui.Rect.fromLTWH(0, 0, side, side);
  canvas
    ..save()
    ..clipRect(frame)
    ..drawRect(frame, ui.Paint()..color = coverEmptyColor);
  paintCoverImage(canvas, side, image, transform);
  canvas.restore();
}

/// [paintCover]와 같은 자리에 그림만 그린다 (바탕 · 자르기 없음). 편집 화면이 칸 밖으로 나간 부분도
/// 보여 주려고 쓴다. 칸의 왼쪽 위가 캔버스의 (0, 0)이다.
void paintCoverImage(
  ui.Canvas canvas,
  double side,
  ui.Image image,
  CoverTransform transform,
) {
  final p = transform.placement(image.width / image.height);
  canvas
    ..save()
    ..translate(p.cx * side, p.cy * side)
    ..rotate(p.radians)
    ..drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromCenter(
        center: ui.Offset.zero,
        width: p.w * side,
        height: p.h * side,
      ),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    )
    ..restore();
}
