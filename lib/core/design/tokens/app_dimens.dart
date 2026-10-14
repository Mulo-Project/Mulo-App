import 'package:flutter/widgets.dart';

/// 간격 (4pt 그리드).
abstract final class AppSpacing {
  /// 제목과 바로 아래 부제 사이 같은 아주 좁은 틈.
  static const double hair = 2;
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

/// 모서리 반경. 작게 쓴다 (기본 12 안팎).
abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;

  /// 큰 카드 (재생목록 · 보관함 요약 · 플레이어 커버).
  static const double card = 20;

  /// 바텀 시트 윗모서리 · 대화상자 · 안내 메시지.
  static const double sheet = md;
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
  /// 넘어가는 동안 앱 전체가 프레임마다 다시 그려지므로 짧게 둔다.
  static const Duration themeSwap = Duration(milliseconds: 260);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// 아이콘 · 컨트롤 크기.
abstract final class AppSizes {
  static const double circleButton = 44;
  static const double circleButtonLarge = 56;

  /// 목록 줄 오른쪽의 작은 아이콘 버튼 ([RowIconButton]).
  static const double rowButton = 36;
  static const double pillHeight = 48;
  static const double miniPlayerHeight = 84;
  static const double navBarHeight = 64;

  /// 아이콘 크기 단계. 글자 옆 작은 표시는 [iconXs] · [iconSm], 줄 · 메뉴는 [iconMd],
  /// 버튼 안 기본은 [icon], 조금 큰 강조는 [iconLg], 빈 화면 안내는 [iconEmpty].
  static const double iconXs = 16;
  static const double iconSm = 18;
  static const double iconMd = 20;
  static const double icon = 22;
  static const double iconLg = 24;
  static const double iconEmpty = 40;
}

/// 유리 면 설정.
abstract final class AppGlass {
  /// 뒤 배경 흐림 정도.
  static const double blur = 24;

  /// 색 유리 카드 채움 불투명도 (밝은 쪽 → 어두운 쪽). 다크.
  static const List<double> tintOpacity = [.78, .5, .32];

  /// 라이트: 옅게 칠해 글자는 기본 글자색(어두운 색) 그대로 읽히게.
  static const List<double> tintOpacityLight = [.42, .26, .16];
}
