import 'package:flutter/material.dart';

import 'app_palette.dart';

/// 글자 스타일. 색은 팔레트에서 받아 테마가 바뀌면 같이 바뀐다.
///
/// 큰 숫자(재생 시간, 곡 수 등)는 [StatNumber] 컴포넌트를 쓴다.
abstract final class AppTypography {
  /// 기본 글꼴. pubspec.yaml `fonts`에 등록 (400 · 500 · 600 · 700).
  static const String fontFamily = 'Pretendard';

  static TextTheme textTheme(AppPalette p) {
    TextStyle s(double size, FontWeight w, {double? height, double ls = 0}) =>
        TextStyle(
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: ls,
          color: p.onSurface,
          fontFamily: fontFamily,
        );

    return TextTheme(
      displayLarge: s(56, FontWeight.w700, height: 1.05, ls: -1.5),
      displayMedium: s(44, FontWeight.w700, height: 1.08, ls: -1),
      displaySmall: s(36, FontWeight.w700, height: 1.1, ls: -.5),
      headlineLarge: s(32, FontWeight.w700, height: 1.15, ls: -.5),
      headlineMedium: s(26, FontWeight.w700, height: 1.2, ls: -.3),
      headlineSmall: s(22, FontWeight.w600, height: 1.25),
      titleLarge: s(20, FontWeight.w600, height: 1.3),
      titleMedium: s(16, FontWeight.w600, height: 1.35),
      titleSmall: s(14, FontWeight.w600, height: 1.35),
      bodyLarge: s(16, FontWeight.w400, height: 1.5),
      bodyMedium: s(14, FontWeight.w400, height: 1.45),
      bodySmall: s(
        12,
        FontWeight.w400,
        height: 1.4,
      ).copyWith(color: p.onSurfaceMuted),
      labelLarge: s(15, FontWeight.w600, ls: .2),
      labelMedium: s(12, FontWeight.w600, ls: .4),
      labelSmall: s(
        11,
        FontWeight.w500,
        ls: .8,
      ).copyWith(color: p.onSurfaceMuted),
    );
  }
}
