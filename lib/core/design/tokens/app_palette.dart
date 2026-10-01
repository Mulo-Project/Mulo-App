import 'package:flutter/material.dart';

import '../contrast.dart';

/// 앱 전체 색 토큰.
///
/// 위젯은 색을 직접 쓰지 않고 항상 이 팔레트(= `context.tokens.palette`)에서 읽는다.
/// 테마 소스(기본 · 사용자 지정 · 곡 분위기)는 모두 [AppPalette]를 만들어 내는 것으로 끝난다.
@immutable
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.outline,
    required this.glassFill,
    required this.glassBorder,
    required this.glassHighlight,
    required this.onGlow,
    required this.scrim,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.glowTertiary,
  });

  /// 모든 글로우 그라데이션은 같은 개수의 색을 가진다 (lerp를 위해).
  static const int glowStops = 3;

  // 기본 레퍼런스 팔레트 원색.
  static const Color black = Color(0xFF000000);
  static const Color violet = Color(0xFF7D39EB);
  static const Color lime = Color(0xFFC6FF33);
  static const Color white = Color(0xFFFFFFFF);

  /// 브랜드 색: 테마와 상관없이 항상 같다 (유튜브 아이콘).
  static const Color youtubeRed = Color(0xFFFF0000);

  // 라이트 테마 수채화 팔레트 원색.
  static const Color watercolorLavender = Color(0xFF9A8CF0);
  static const Color watercolorCoral = Color(0xFFE8708F);

  /// 기본 테마: 검정 배경 · 바이올렛 · 라임.
  static const AppPalette defaultDark = AppPalette(
    background: black,
    surface: Color(0xFF111113),
    surfaceHigh: Color(0xFF1E1E22),
    onSurface: white,
    onSurfaceMuted: Color(0x99FFFFFF),
    outline: Color(0x33FFFFFF),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x24FFFFFF),
    glassHighlight: Color(0x73FFFFFF),
    onGlow: white,
    scrim: black,
    primary: violet,
    onPrimary: white,
    accent: lime,
    onAccent: black,
    // 마젠타 → 바이올렛 → 짙은 보라
    glowPrimary: [Color(0xFFE040FB), violet, Color(0xFF2A0E5C)],
    // 인디고 → 네이비 → 거의 검정
    glowSecondary: [Color(0xFF5B5BF0), Color(0xFF1B2266), Color(0xFF070A1F)],
    // 주황 → 빨강 → 짙은 적갈
    glowTertiary: [Color(0xFFFF8A3D), Color(0xFFE5322D), Color(0xFF3A0B0B)],
  );

  /// 라이트 테마 바탕 (옅은 크림빛 배경 · 흰 면). 색 · 글로우는 수채화처럼 연한 파스텔 계열.
  static const AppPalette _lightBase = AppPalette(
    background: Color(0xFFFBF8FF),
    surface: white,
    surfaceHigh: Color(0xFFF1ECFA),
    onSurface: Color(0xFF1B1830),
    onSurfaceMuted: Color(0x991B1830),
    outline: Color(0x1A3A2E6B),
    glassFill: Color(0x99FFFFFF),
    glassBorder: Color(0x1F3A2E6B),
    glassHighlight: Color(0xE6FFFFFF),
    onGlow: white,
    scrim: black,
    primary: watercolorLavender,
    onPrimary: white,
    accent: watercolorCoral,
    onAccent: white,
    // 분홍 → 라벤더 → 푸른 보라 (수채화 번짐)
    glowPrimary: [Color(0xFFF7A8CB), watercolorLavender, Color(0xFF6A78D8)],
    // 하늘 → 물빛 → 짙은 청회
    glowSecondary: [Color(0xFF8ECFF5), Color(0xFF6C9BE0), Color(0xFF3F5CA8)],
    // 살구 → 산호 → 짙은 장밋빛
    glowTertiary: [Color(0xFFFFC08A), Color(0xFFF08A8A), Color(0xFFB04A6A)],
  );

  /// 기본 라이트 테마: 수채화 파스텔. 강조 색은 밝은 배경에서도 보이도록 대비 3:1을 지킨다.
  static final AppPalette defaultLight = _withAccent(
    _lightBase,
    watercolorCoral,
    3,
  );

  /// 밝기별 기본 바탕.
  static AppPalette baseFor(Brightness b) =>
      b == Brightness.dark ? defaultDark : _lightBase;

  /// 밝기별 강조 색 최소 대비. 다크 7:1, 라이트 3:1(밝은 배경에서 형광색은 대비가 낮아서).
  static double accentContrastFor(Brightness b) => b == Brightness.dark ? 7 : 3;

  static AppPalette _withAccent(AppPalette base, Color accent, double min) {
    final a = ensureContrast(accent, base.background, min);
    return base.copyWith(accent: a, onAccent: bestOn(a));
  }

  /// 배경 밝기로 판단한 테마 밝기.
  Brightness get brightness =>
      background.computeLuminance() > .5 ? Brightness.light : Brightness.dark;

  /// 주 색 · 강조 색 두 개로 팔레트를 만든다.
  ///
  /// 사용자 지정 테마와 곡 분위기 테마가 공유하는 규칙:
  /// - 배경 · 표면은 기본(검정 계열)을 유지한다.
  /// - 강조 색은 배경 대비 [minAccentContrast] 이상이 되도록 밝힌다.
  /// - 글로우 그라데이션은 두 색에서 유도한다 ([glowSecondary]는 주 색을 어둡게 한 톤).
  factory AppPalette.derive({
    required Color primary,
    required Color accent,
    Color? tertiary,
    AppPalette base = defaultDark,
    double minAccentContrast = 7,
  }) {
    final bg = base.background;
    final safeAccent = ensureContrast(accent, bg, minAccentContrast);
    final safePrimary = ensureContrast(primary, bg, 3);
    final third = tertiary ?? _shiftHue(safePrimary, -60);

    return base.copyWith(
      primary: safePrimary,
      onPrimary: bestOn(safePrimary),
      accent: safeAccent,
      onAccent: bestOn(safeAccent),
      glowPrimary: [
        _shiftHue(_lighten(safePrimary, .12), 30),
        safePrimary,
        _darken(safePrimary, .32),
      ],
      glowSecondary: [
        _lighten(_shiftHue(safePrimary, 40), .02),
        _darken(safePrimary, .28),
        _darken(safePrimary, .42),
      ],
      glowTertiary: [_lighten(third, .08), third, _darken(third, .36)],
    );
  }

  final Color background;
  final Color surface;

  /// 원형 아이콘 버튼 · 톤 버튼처럼 표면 위에 한 단계 뜬 면.
  final Color surfaceHigh;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color outline;

  /// 유리 면 채움 (배경이 비치는 옅은 흰색).
  final Color glassFill;

  /// 유리 면 테두리 기본색.
  final Color glassBorder;

  /// 유리 가장자리에 빛이 맺히는 부분 (왼쪽 위 테두리).
  final Color glassHighlight;

  /// 색 유리 카드 · 사진 · 그라데이션 위 글자 (테마 밝기와 관계없이 밝은 색).
  final Color onGlow;

  /// 사진 위 글자를 읽히게 덮는 어두운 막.
  final Color scrim;

  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color onAccent;

  /// 유리 카드 · 배경 빛에 쓰는 그라데이션 (밝은 쪽 → 어두운 쪽).
  final List<Color> glowPrimary;
  final List<Color> glowSecondary;
  final List<Color> glowTertiary;

  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? outline,
    Color? glassFill,
    Color? glassBorder,
    Color? glassHighlight,
    Color? onGlow,
    Color? scrim,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? onAccent,
    List<Color>? glowPrimary,
    List<Color>? glowSecondary,
    List<Color>? glowTertiary,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      outline: outline ?? this.outline,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      onGlow: onGlow ?? this.onGlow,
      scrim: scrim ?? this.scrim,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      glowPrimary: glowPrimary ?? this.glowPrimary,
      glowSecondary: glowSecondary ?? this.glowSecondary,
      glowTertiary: glowTertiary ?? this.glowTertiary,
    );
  }

  static AppPalette lerp(AppPalette a, AppPalette b, double t) {
    if (identical(a, b)) return a;
    assert(
      [a, b].every(
        (p) => [
          p.glowPrimary,
          p.glowSecondary,
          p.glowTertiary,
        ].every((g) => g.length == glowStops),
      ),
      '글로우 그라데이션은 $glowStops색이어야 한다',
    );
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    List<Color> l(List<Color> x, List<Color> y) => [
      for (var i = 0; i < x.length; i++) c(x[i], y[i]),
    ];
    return AppPalette(
      background: c(a.background, b.background),
      surface: c(a.surface, b.surface),
      surfaceHigh: c(a.surfaceHigh, b.surfaceHigh),
      onSurface: c(a.onSurface, b.onSurface),
      onSurfaceMuted: c(a.onSurfaceMuted, b.onSurfaceMuted),
      outline: c(a.outline, b.outline),
      glassFill: c(a.glassFill, b.glassFill),
      glassBorder: c(a.glassBorder, b.glassBorder),
      glassHighlight: c(a.glassHighlight, b.glassHighlight),
      onGlow: c(a.onGlow, b.onGlow),
      scrim: c(a.scrim, b.scrim),
      primary: c(a.primary, b.primary),
      onPrimary: c(a.onPrimary, b.onPrimary),
      accent: c(a.accent, b.accent),
      onAccent: c(a.onAccent, b.onAccent),
      glowPrimary: l(a.glowPrimary, b.glowPrimary),
      glowSecondary: l(a.glowSecondary, b.glowSecondary),
      glowTertiary: l(a.glowTertiary, b.glowTertiary),
    );
  }

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0, 1)).toColor();
  }

  static Color _darken(Color c, double amount) => _lighten(c, -amount);

  static Color _shiftHue(Color c, double degrees) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withHue((hsl.hue + degrees) % 360).toColor();
  }
}
