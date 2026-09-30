# 디자인 시스템

위치: `lib/core/design/` (한 번에 가져오기: `core/design/design.dart`)

## 규칙
- 위젯은 색 · 그라데이션을 **토큰에서만** 읽는다: `context.palette.accent`, `context.tokens.glow(GlowTone.primary)`.
  `Color(0x…)`, `Colors.xxx`를 화면 코드에 쓰지 않는다. (예외: 테마 소스 입력값)
- 간격 · 반경 · 시간은 `AppSpacing` · `AppRadii` · `AppMotion` · `AppSizes`.
- 글자는 `Theme.of(context).textTheme` (글꼴 Pretendard 400 · 500 · 600 · 700), 큰 숫자는 `StatNumber`.
- **유리**(`GlassSurface` · `GlassCard`: 뒤를 흐리게 비추는 반투명 면 + 왼쪽 위 빛 테두리)는 일부에만 쓴다 (D-015):
  떠 있는 미니 플레이어 · 하단 탭, 원형 버튼 · 보조(tonal) 버튼, 강조 카드(보관함 · 다운로드 요약, 검색 결과).
- 배경(`AppBackground`)은 단색. 설정 묶음 · 입력칸 · 선택 알약 · 스위치는 평범한 면(`surface` · `surfaceHigh` + `outline`).
- 이미지가 들어가는 카드(재생목록, 플레이어 커버)는 유리 없이 `CoverCard` (사진, 없으면 테마 색 그라데이션).
- 색 유리 카드 · 사진 위 글자는 `onGlow`(항상 밝은 색) — `GlassCard` · `CoverCard`가 자동으로 적용.

## 구조
| 파일 | 역할 |
|---|---|
| `tokens/app_palette.dart` | 색 토큰 `AppPalette` (기본 = 검정 #000 · 바이올렛 #7D39EB · 라임 #C6FF33 · 흰색). 유리 토큰 `glassFill` · `glassBorder` · `glassHighlight`. `derive()`로 두 색에서 팔레트 생성, `lerp()` |
| `tokens/app_dimens.dart` | 간격 · 반경 · 모션 · 크기 · 유리(`AppGlass` 흐림 · 채움 불투명도) |
| `tokens/app_typography.dart` | TextTheme |
| `app_theme_tokens.dart` | `ThemeExtension<AppThemeTokens>` (copyWith · lerp), `context.tokens` / `context.palette` |
| `app_theme.dart` | `buildAppTheme(palette)` → ThemeData |
| `contrast.dart` | 대비율 계산 · 보정 (`ensureContrast`, `bestOn`) |
| `theme_source/` | `ThemeSource` 인터페이스 + `ThemePreset`(8개) / Custom / Mood |
| `theme_controller.dart` | Riverpod `themeControllerProvider`, `apply(source)` / `reset()` |
| `components/` | 아래 "컴포넌트" 표 |

## 테마 전환 흐름
`ThemeSource.resolve()` → `AppPalette` → `ThemeController.state` → `buildAppTheme` →
MaterialApp `themeAnimationDuration`(700ms) 동안 `AppThemeTokens.lerp`로 부드럽게 전환.

## 테마 프리셋
바이올렛(기본) · 코랄 · 오션 · 포레스트 · 선셋 · 로즈 · 골드 · 아이스. 설정 › 테마 색에서 고르고 `shared_preferences`(`theme.preset`)에 저장해 다음 실행 때 불러온다.
프리셋은 주 색 · 강조 색 두 개만 정하고 나머지는 `AppPalette.derive`가 만든다 (배경 검정, 강조 색 대비 7:1 이상 — 테스트로 확인).
`ThemeController.selectPreset`(저장) / `apply`(임시, 곡 분위기 등) / `reset`(고른 프리셋으로 복귀).

## 확장
- **사용자 지정 테마**: `CustomThemeStore` 구현(예: SharedPreferences)을 붙이고, 앱 시작 시
  `load()` → `apply(CustomThemeSource(spec))`. 색 선택 화면은 `save(spec)` 후 `apply`.
- **곡 분위기 테마**: 현재 곡이 바뀔 때 `apply(MoodThemeSource(trackId:, artwork:))`.
  배경은 검정 유지, 강조 색은 배경 대비 7:1 이상으로 자동 보정. 늦게 끝난 이전 곡 추출 결과는 버린다.
- 우선순위: "곡 분위기 따라가기" 설정이 켜져 있을 때만 분위기 테마, 꺼져 있으면 사용자 지정(없으면 기본) — D-005. 분기 구현은 설정 화면 때.

## 컴포넌트
화면은 이 컴포넌트로 만든다. 필요한 모양이 없으면 여기에 추가하고 표에 적는다.
문구는 컴포넌트 안에 넣지 않고 밖에서 받는다 (다국어).

| 컴포넌트 | 파일 | 용도 |
|---|---|---|
| `AppBackground` | app_background.dart | 단색 배경 (앱 틀 · 플레이어) |
| `GlassSurface` | glass.dart | 유리 면 기본형 (무색 또는 `tint` 색), 모양 · 탭 · 빛 |
| `GlassCard` | glass.dart | 색 유리 강조 카드, `GlowTone` primary · secondary · tertiary |
| `CoverCard` · `onGlow()` | cover_card.dart | 이미지 카드 (재생목록 · 플레이어 커버), 색 · 사진 위 글자색 |
| `StatNumber` | stat_number.dart | 큰 숫자 (곡 수, 시간, 퍼센트), 고정폭 숫자 |
| `PillButton` | buttons.dart | 알약 버튼: accent · primary(단색 + 빛), tonal(유리), outline |
| `CircleIconButton` | buttons.dart | 원형 유리 버튼, `emphasized` = 강조 색 + 빛 (재생) |
| `ProgressRing` · `ProgressLine` | progress.dart | 원형 · 막대 진행 표시 (강조 색 + 빛) |
| `MiniPlayerBar` | mini_player_bar.dart | 유리 미니 플레이어 |
| `AppTopBar` | app_top_bar.dart | 상단 바. `large` = 탭 첫 화면(부제 + 큰 제목), 기본 = 원형 버튼 사이 가운데 제목 |
| `AppBottomNav` | app_bottom_nav.dart | 떠 있는 유리 탭 바 (선택 = 강조 색 + 점) |
| `AppSearchField` | app_search_field.dart | 알약 입력칸 (돋보기 · 지우기 · 오른쪽 버튼) |
| `ArtworkBox` · `toneFor()` | artwork_box.dart | 커버 자리 (없으면 그라데이션), 키별 고정 톤 |
| `TrackTile` | track_tile.dart | 곡 한 줄 (커버 · 제목 · 부제 · 오른쪽 · 아래 줄) |
| `AppSwitch` | app_switch.dart | 토글 (켜짐 = 강조 색) |
| `SectionCard` · `SettingRow` | section_card.dart | 설정 묶음 · 한 줄 |
| `SegmentedPills` · `StatusPill` | segmented_pills.dart | 하나 고르기 알약 묶음 · 상태 알약 |
| `ThemeSwatch` | theme_swatch.dart | 테마 프리셋 미리보기 동그라미 (다른 팔레트를 그리는 유일한 컴포넌트) |

Material 버튼 · AppBar · ListTile · Switch · Chip · Slider는 화면에서 직접 쓰지 않는다 (위 컴포넌트로 대체).

## 앱 틀 레이아웃
- `Scaffold(extendBody: true)`: 내용이 유리 미니 플레이어 · 탭 바 뒤로 흘러가며 흐리게 비친다.
- 탭 화면의 스크롤 목록은 아래 여백을 `MediaQuery.paddingOf(context).bottom`만큼 더 둔다.
- 유리(BackdropFilter)는 비용이 있으니 목록의 줄마다 쓰지 않는다 (카드 · 묶음 · 바에만).
