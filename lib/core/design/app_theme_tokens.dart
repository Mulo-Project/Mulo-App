import 'package:flutter/material.dart';

import 'tokens/app_palette.dart';

/// 글로우 카드 등에서 고르는 그라데이션 톤. 실제 색은 팔레트가 정한다.
enum GlowTone { primary, secondary, tertiary }

/// ThemeData에 붙는 앱 전용 토큰.
///
/// [lerp]가 있어 MaterialApp의 테마 애니메이션(AnimatedTheme)이
/// 그라데이션 · 강조 색까지 부드럽게 넘긴다.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({required this.palette});

  final AppPalette palette;

  List<Color> glow(GlowTone tone) => switch (tone) {
    GlowTone.primary => palette.glowPrimary,
    GlowTone.secondary => palette.glowSecondary,
    GlowTone.tertiary => palette.glowTertiary,
  };

  @override
  AppThemeTokens copyWith({AppPalette? palette}) =>
      AppThemeTokens(palette: palette ?? this.palette);

  @override
  AppThemeTokens lerp(covariant AppThemeTokens? other, double t) {
    if (other == null) return this;
    return AppThemeTokens(palette: AppPalette.lerp(palette, other.palette, t));
  }
}

extension AppThemeTokensX on BuildContext {
  /// 현재 토큰. 위젯은 색을 반드시 여기서 읽는다.
  AppThemeTokens get tokens =>
      Theme.of(this).extension<AppThemeTokens>() ??
      const AppThemeTokens(palette: AppPalette.defaultDark);

  AppPalette get palette => tokens.palette;
}
