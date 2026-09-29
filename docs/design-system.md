# 디자인 시스템

위치: `lib/core/design/` (한 번에 가져오기: `core/design/design.dart`)

## 규칙
- 위젯은 색 · 그라데이션을 **토큰에서만** 읽는다: `context.palette.accent`, `context.tokens.glow(GlowTone.primary)`.
  `Color(0x…)`, `Colors.xxx`를 화면 코드에 쓰지 않는다. (예외: 테마 소스 입력값)
- 간격 · 반경 · 시간은 `AppSpacing` · `AppRadii` · `AppMotion` · `AppSizes`.
- 글자는 `Theme.of(context).textTheme` (글꼴 Pretendard 400 · 500 · 600 · 700), 큰 숫자는 `DotMatrixText`.

## 구조
| 파일 | 역할 |
|---|---|
| `tokens/app_palette.dart` | 색 토큰 `AppPalette` (기본 = 검정 #000 · 바이올렛 #7D39EB · 라임 #C6FF33 · 흰색). `derive()`로 두 색에서 팔레트 생성, `lerp()` |
| `tokens/app_dimens.dart` | 간격 · 반경 · 모션 · 크기 |
| `tokens/app_typography.dart` | TextTheme |
| `app_theme_tokens.dart` | `ThemeExtension<AppThemeTokens>` (copyWith · lerp), `context.tokens` / `context.palette` |
| `app_theme.dart` | `buildAppTheme(palette)` → ThemeData |
| `contrast.dart` | 대비율 계산 · 보정 (`ensureContrast`, `bestOn`) |
| `theme_source/` | `ThemeSource` 인터페이스 + Default / Custom / Mood |
| `theme_controller.dart` | Riverpod `themeControllerProvider`, `apply(source)` / `reset()` |
| `components/` | DotGridBackground, GlowCard, DotMatrixText, PillButton, CircleIconButton, DottedProgressArc/Bar, MiniPlayerBar |

## 테마 전환 흐름
`ThemeSource.resolve()` → `AppPalette` → `ThemeController.state` → `buildAppTheme` →
MaterialApp `themeAnimationDuration`(700ms) 동안 `AppThemeTokens.lerp`로 부드럽게 전환.

## 확장
- **사용자 지정 테마**: `CustomThemeStore` 구현(예: SharedPreferences)을 붙이고, 앱 시작 시
  `load()` → `apply(CustomThemeSource(spec))`. 색 선택 화면은 `save(spec)` 후 `apply`.
- **곡 분위기 테마**: 현재 곡이 바뀔 때 `apply(MoodThemeSource(trackId:, artwork:))`.
  배경은 검정 유지, 강조 색은 배경 대비 7:1 이상으로 자동 보정. 늦게 끝난 이전 곡 추출 결과는 버린다.
- 우선순위: "곡 분위기 따라가기" 설정이 켜져 있을 때만 분위기 테마, 꺼져 있으면 사용자 지정(없으면 기본) — D-005. 분기 구현은 설정 화면 때.
