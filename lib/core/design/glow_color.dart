import 'package:flutter/painting.dart';

/// 사용자가 고른 색 하나에서 커버 그라데이션 3단(밝게 · 원래 색 · 어둡게)을 만든다.
/// 테마 팔레트와 상관없이 고른 색 그대로 보인다. 흰 글자가 읽히도록 너무 밝은 색은 눌러 준다.
List<Color> glowFromColor(Color base) {
  final hsl = HSLColor.fromColor(base);
  final mid = hsl.withLightness(hsl.lightness.clamp(.28, .56));
  return [
    mid.withLightness((mid.lightness + .14).clamp(0, 1)).toColor(),
    mid.toColor(),
    mid.withLightness((mid.lightness - .22).clamp(0, 1)).toColor(),
  ];
}
