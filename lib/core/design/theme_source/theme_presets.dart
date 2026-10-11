import 'package:flutter/material.dart' show Brightness, Color;

import '../tokens/app_palette.dart';
import 'theme_source.dart';

/// 설정에서 고르는 테마 색 프리셋 (상세 기능: 테마 색 고르기).
///
/// 배경 · 표면은 모두 검정 계열로 같고, 유리 색 · 배경 빛 · 강조 색만 바뀐다.
/// 강조 색 대비는 [AppPalette.derive]가 보정한다.
enum ThemePreset implements ThemeSource {
  violet(AppPalette.violet, AppPalette.lime),
  coral(
    Color(0xFFFF3D7F),
    Color(0xFF33E1FF),
    lightPrimary: Color(0xFFF2487F),
    lightAccent: Color(0xFF1A9FCB),
  ),
  ocean(
    Color(0xFF1E6BFF),
    Color(0xFF5CF2D6),
    lightPrimary: Color(0xFF2F7BFF),
    lightAccent: Color(0xFF0E9E8C),
  ),
  forest(
    Color(0xFF1FA35C),
    Color(0xFFFFD166),
    lightPrimary: Color(0xFF2DAA6A),
    lightAccent: Color(0xFFD08A00),
  ),
  sunset(
    Color(0xFFFF6B2C),
    Color(0xFFFFD23F),
    lightPrimary: Color(0xFFFF7A3D),
    lightAccent: Color(0xFFD9820B),
  ),
  rose(
    Color(0xFFE0457B),
    Color(0xFFFFC2D9),
    lightPrimary: Color(0xFFE8588D),
    lightAccent: Color(0xFFC23A74),
  ),
  gold(
    Color(0xFFC9962B),
    Color(0xFFFFF1B8),
    lightPrimary: Color(0xFFD9A23A),
    lightAccent: Color(0xFFA8691A),
  ),
  ice(
    Color(0xFF6FA8FF),
    Color(0xFFE6F4FF),
    lightPrimary: Color(0xFF5E9BFF),
    lightAccent: Color(0xFF2A9FD6),
  );

  const ThemePreset(
    this.primary,
    this.accent, {
    this.lightPrimary,
    this.lightAccent,
  });

  final Color primary;
  final Color accent;

  /// 라이트 테마용 색. 다크용 형광 · 파스텔 강조 색은 밝은 배경에서 탁해지므로 따로 둔다.
  /// 없으면 [primary] · [accent]를 쓴다.
  final Color? lightPrimary;
  final Color? lightAccent;

  static const ThemePreset initial = violet;

  @override
  String get id => 'preset:$name';

  /// 기본(바이올렛)은 손으로 맞춘 기본 팔레트, 나머지는 두 색에서 유도.
  AppPalette paletteFor(Brightness brightness) {
    if (this == violet) {
      return brightness == Brightness.dark
          ? AppPalette.defaultDark
          : AppPalette.defaultLight;
    }
    final light = brightness == Brightness.light;
    return AppPalette.derive(
      primary: light ? lightPrimary ?? primary : primary,
      accent: light ? lightAccent ?? accent : accent,
      tertiary: light ? lightAccent : null,
      base: AppPalette.baseFor(brightness),
      minAccentContrast: AppPalette.accentContrastFor(brightness),
    );
  }

  @override
  AppPalette resolve(Brightness brightness) => paletteFor(brightness);

  static ThemePreset? fromId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}
