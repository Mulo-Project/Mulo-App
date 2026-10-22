import 'dart:ui' as ui;

import '../../features/covers/domain/entities/cover_art.dart';

/// [image]를 [transform]대로 정사각형 [side] 칸에 그린다: 검정 바탕 위에 이동 · 확대 · 회전.
/// 목록 · 카드 · 편집 화면 · 파일 태그의 커버가 모두 이 한 곳의 규칙을 쓴다.
void paintCover(
  ui.Canvas canvas,
  double side,
  ui.Image image,
  CoverTransform transform,
) {
  final p = transform.placement(image.width / image.height);
  canvas
    ..save()
    ..clipRect(ui.Rect.fromLTWH(0, 0, side, side))
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, side, side),
      ui.Paint()..color = const ui.Color(0xFF000000),
    )
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
