import 'package:flutter/painting.dart';

/// WCAG 대비율 (1 ~ 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [fg]가 [bg] 대비 [minRatio] 이상이 될 때까지 명도를 조정한다.
/// 배경이 어두우면 밝히고, 밝으면 어둡힌다. 색상(hue)은 유지한다.
Color ensureContrast(Color fg, Color bg, double minRatio) {
  if (contrastRatio(fg, bg) >= minRatio) return fg;
  final darkBg = bg.computeLuminance() < 0.5;
  var hsl = HSLColor.fromColor(fg);
  for (var i = 0; i < 40; i++) {
    final next = (hsl.lightness + (darkBg ? 0.025 : -0.025)).clamp(0.0, 1.0);
    hsl = hsl.withLightness(next);
    final color = hsl.toColor();
    if (contrastRatio(color, bg) >= minRatio || next == 0 || next == 1) {
      return color;
    }
  }
  return hsl.toColor();
}

/// [bg] 위에 올릴 글자색: 검정 · 흰색 중 대비가 큰 쪽.
Color bestOn(Color bg) {
  const black = Color(0xFF000000);
  const white = Color(0xFFFFFFFF);
  return contrastRatio(black, bg) >= contrastRatio(white, bg) ? black : white;
}
