import 'package:flutter/painting.dart';

import '../tokens/app_palette.dart';
import 'theme_source.dart';

/// 설정에서 고르는 테마 색 프리셋 (상세 기능: 테마 색 고르기).
///
/// 배경 · 표면은 모두 검정 계열로 같고, 유리 색 · 배경 빛 · 강조 색만 바뀐다.
/// 강조 색 대비는 [AppPalette.derive]가 보정한다.
enum ThemePreset implements ThemeSource {
  violet(AppPalette.violet, AppPalette.lime),
  coral(Color(0xFFFF3D7F), Color(0xFF33E1FF)),
  ocean(Color(0xFF1E6BFF), Color(0xFF5CF2D6)),
  forest(Color(0xFF1FA35C), Color(0xFFFFD166)),
  sunset(Color(0xFFFF6B2C), Color(0xFFFFD23F)),
  rose(Color(0xFFE0457B), Color(0xFFFFC2D9)),
  gold(Color(0xFFC9962B), Color(0xFFFFF1B8)),
  ice(Color(0xFF6FA8FF), Color(0xFFE6F4FF));

  const ThemePreset(this.primary, this.accent);

  final Color primary;
  final Color accent;

  static const ThemePreset initial = violet;

  @override
  String get id => 'preset:$name';

  /// 기본(바이올렛)은 손으로 맞춘 기본 팔레트, 나머지는 두 색에서 유도.
  AppPalette get palette => this == violet
      ? AppPalette.defaultDark
      : AppPalette.derive(primary: primary, accent: accent);

  @override
  AppPalette resolve() => palette;

  static ThemePreset? fromId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}
