import 'package:flutter/widgets.dart';

/// 간격 (4pt 그리드).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// 화면 좌우 기본 여백.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: md);
}

/// 모서리 반경.
abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;

  /// 레퍼런스의 큰 카드.
  static const double card = 32;
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
}

/// 애니메이션 시간 · 곡선.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);

  /// 테마 소스가 바뀔 때 색이 넘어가는 시간 (곡 전환 시 분위기 테마 포함).
  static const Duration themeSwap = Duration(milliseconds: 700);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// 아이콘 · 컨트롤 크기.
abstract final class AppSizes {
  static const double circleButton = 44;
  static const double circleButtonLarge = 56;
  static const double pillHeight = 48;
  static const double miniPlayerHeight = 72;
  static const double icon = 22;
}
