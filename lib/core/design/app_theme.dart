import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';
import 'tokens/app_palette.dart';
import 'tokens/app_typography.dart';

/// 팔레트 하나로 ThemeData를 만든다. 어떤 테마 소스든 여기를 거친다.
ThemeData buildAppTheme(AppPalette p) {
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.accent,
    onSecondary: p.onAccent,
    tertiary: p.glowTertiary[1],
    onTertiary: p.onSurface,
    error: const Color(0xFFFF5A5F),
    onError: p.background,
    surface: p.surface,
    onSurface: p.onSurface,
    onSurfaceVariant: p.onSurfaceMuted,
    surfaceContainerHighest: p.surfaceHigh,
    outline: p.outline,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    fontFamily: AppTypography.fontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    textTheme: AppTypography.textTheme(p),
    iconTheme: IconThemeData(color: p.onSurface),
    splashFactory: InkSparkle.splashFactory,
    extensions: [AppThemeTokens(palette: p)],
  );
}
