# 디자인 시스템

위치: `lib/core/design/` (한 번에 가져오기: `core/design/design.dart`)

## 규칙
- 위젯은 색 · 그라데이션을 **토큰에서만** 읽는다: `context.palette.accent`, `context.tokens.glow(GlowTone.primary)`.
  `Color(0x…)`, `Colors.xxx`를 화면 코드에 쓰지 않는다. (예외: 테마 소스 입력값)
- 간격 · 반경 · 시간은 `AppSpacing` · `AppRadii` · `AppMotion` · `AppSizes`.
- 반경은 작게: 기본 `AppRadii.sm`(12), 큰 카드 · 시트 · 대화상자도 16~20 (D-106).
- 아이콘 크기는 `AppSizes` 단계만 쓴다: `iconXs` 16 (글자 옆 작은 표시) · `iconSm` 18 (체크 · 펼치기) · `iconMd` 20 (줄 · 메뉴 · 입력칸) · `icon` 22 (버튼 안 기본) · `iconLg` 24 · `iconEmpty` 40 (빈 화면).
- 제목과 바로 아래 부제 사이는 `AppSpacing.hair`(2).
- 바텀 시트는 모두 `showAppSheet`로 열고 안쪽 여백은 `appSheetPadding`(가로 16), 제목은 `AppSheetTitle`. 빈 화면 · 연결 필요 · 로그인 필요 안내는 `EmptyState`, 불러오는 중은 `LoadingState`(작게는 `LoadingIndicator`).
- 설명 문구(`...Desc`)와 안내 본문은 문장이면 마침표로 끝낸다. 제목 · 버튼 · 안내 메시지(스낵바)는 마침표 없이.
- 글자는 `Theme.of(context).textTheme` (글꼴 Pretendard 400 · 500 · 600 · 700), 큰 숫자는 `StatNumber`.
- **유리**(`GlassSurface` · `GlassCard`: 뒤를 흐리게 비추는 반투명 면 + 왼쪽 위 빛 테두리)는 일부에만 쓴다 (D-015):
  가로 전체 미니 플레이어(모서리 둥글지 않음) · 하단 탭, 원형 버튼 · 보조(tonal) 버튼, 보관함 요약 카드.
- **카드는 보관함 · 재생목록에만** 쓴다 (D-033). 홈은 구역마다 모양이 다른 전용 디자인이고 공통 컴포넌트로 묶지 않는다 (D-035). 검색 · 설정은 면 없이 제목 + 본문 + 구분선.
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

## 화면 모드 (다크 · 라이트)
설정 › 테마 › 화면 모드: 다크(기본) · 라이트, 기기 설정은 따르지 않는다 (D-016 · D-018). 프리셋마다 `paletteFor(Brightness)`로 두 팔레트를 만든다.
라이트 강조 색은 배경 대비 3:1로 진하게 보정. 위젯은 `context.palette`만 읽으면 두 모드 모두 맞게 나온다.

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
| `GlassSurface` | glass.dart | 유리 면 기본형 (무색 또는 `tint` 색), 모양 · 탭 · 빛. `blur: 0`이면 흐림 층(BackdropFilter)을 만들지 않는다 — 목록 줄마다 놓는 것은 0으로 (스크롤 끊김). `solid: true`는 흐림 없이 배경색(94%)을 깔아 유리처럼 보이게 한다 — 스크롤 화면 위에 늘 떠 있거나 끌려 움직이는 면(미니 플레이어 · 받기 띠 · 플로팅 버튼)에 쓴다 (D-121: 성능이 유리 효과보다 먼저) |
| `GlassCard` | glass.dart | 색 유리 강조 카드, `GlowTone` primary · secondary · tertiary |
| `CoverCard` · `onGlow()` | cover_card.dart | 이미지 카드 (재생목록 · 플레이어 커버), 색 · 사진 위 글자색 |
| `StatNumber` | stat_number.dart | 큰 숫자 (곡 수, 시간, 퍼센트), 고정폭 숫자 |
| `AppLineChart` | line_chart.dart | 꺾은선 그래프 (accent 선 · 점, outline 눈금, 최댓값 글자). 외부 차트 패키지 없음 |
| `PillButton` | buttons.dart | 알약 버튼: accent · primary(단색 + 빛, 비활성이면 빛 끔), tonal(유리), outline(투명 + `outline` 테두리) |
| `CircleIconButton` | buttons.dart | 원형 유리 버튼, `emphasized` = 강조 색 + 빛 (재생); `onLongPress`로 길게 누르기 |
| `RowIconButton` | buttons.dart | 목록 줄 오른쪽 작은 아이콘 버튼 (36px, 면 · 흐림 없음, `accent` = 강조 색, `filled` = 강조 색으로 채운 동그라미(검색 실행 등), `busy` = 돌아가는 표시). 줄마다 `CircleIconButton`(유리)을 놓으면 스크롤이 끊긴다 |
| `PlainButton` | buttons.dart | 면 없는 작은 글자 · 아이콘 버튼 (보조 동작 · 한 줄 여러 개) |
| `MarqueeText` | marquee_text.dart | 한 줄 제목. 칸보다 길 때만 잠깐 멈췄다가 옆으로 흐르고(끝은 흐리게), 들어가면 일반 글자. `scroll: false`면 `…`로 줄임. 플레이어 · 미니 플레이어 · 재생 중인 곡 줄에 쓴다 (목록 전체가 움직이지 않게 나머지 줄은 `…`) |
| `ProgressRing` · `ProgressLine` | progress.dart | 원형 · 막대 진행 표시 (강조 색 + 빛) |
| `CountdownRing` | progress.dart | 버튼 안에 들어가는 작은 원형 진행 (가운데에 남은 초) |
| `MiniPlayerBar` | mini_player_bar.dart | 유리 미니 플레이어 (가로 전체 · 모서리 직각 · 위쪽 선만, 재생 버튼만 원형, 다음 · 대기열은 배경 없는 작은 아이콘, 제목 아래에 작은 출력 기기 표시 `outputIcon`/`outputLabel`). `GlassSurface(rim: false)`로 가장자리 빛 테두리를 끈다 |
| `FloatingPlayerButton` | floating_player_button.dart | 미니 플레이어를 길게 눌러 끌어낸 동그란 플로팅 버튼 (유리 원 + 커버 아트 + 진행 테두리). 가운데 = 재생 · 일시정지, 버튼에서 떨어져 비스듬히 뻗은 거품 점 = 미니 플레이어로 돌아가기 (화면 안쪽 · 벽에 닿으면 반대쪽 면으로 부드럽게 이동). 위치 · 끌기 · 가장자리 붙이기는 `app/mini_float_layer.dart` |
| `AppTopBar` | app_top_bar.dart | 상단 바. `large` = 탭 첫 화면(부제 + 큰 제목), 기본 = 원형 버튼 사이 가운데 제목 |
| `AppBottomNav` | app_bottom_nav.dart | 하단 탭 바 (선택 = 강조 색 + 점). `highlighted` 항목(홈, 가운데)은 강조 색 원 |
| `AppSearchField` | app_search_field.dart | 알약 입력칸 (돋보기 · 지우기 · 오른쪽 버튼). 글자는 세로 가운데 |
| `ArtworkBox` · `toneFor()` | artwork_box.dart | 커버 자리 (이미지 · 사용자 색이 없으면 무채색 `GlowTone.neutral` 그라데이션 + 아이콘; `toneFor()`는 이제 항상 무채색). `width`를 주면 직사각형, `color`를 주면 사용자가 고른 색(`glowFromColor`)으로. 이미지는 칸 크기의 2배(화면 배율 포함) 안으로 줄여 디코딩한다 (`ResizeImage`) |
| `YoutubeMark` | youtube_mark.dart | 유튜브 표시 (직접 그린 빨간 원 + 흰 링 + 흰 재생 삼각형, YouTube Music 모양, 테마와 무관) |
| `SoundcloudMark` | soundcloud_mark.dart | 사운드클라우드 표시 (주황 둥근 사각형 + 검정 파형 막대 + 구름, 테마와 무관) |
| `ColorPicker` | color_picker.dart | 커버 색 고르기 (자동 · 견본 12 · 색상 막대). 사용자가 고르는 색이라 견본은 테마 토큰이 아니라 고정 색 (토큰 규칙의 예외) |
| `TrackTile` | track_tile.dart | 곡 한 줄 (커버 · 제목 · 부제 · 오른쪽 · 아래 줄). `onMenu(Offset)`: 길게 누르기 · 오른쪽 클릭 (눌린 좌표를 넘겨 팝업 메뉴를 그 자리에) |
| `MenuRow` | menu_row.dart | 메뉴 시트의 한 줄 (아이콘 + 글자, 삭제는 `destructive` 경고 색). 면 · 테두리 없이 줄만, 가로 여백 없이 시트 제목과 왼쪽 선을 맞춘다 |
| `showAppSheet` · `AppSheetTitle` · `appSheetPadding` | app_sheet.dart | 공통 바텀 시트 (손잡이 · 윗모서리 `AppRadii.sheet` · 최상위 내비게이터), 시트 제목(titleLarge + 작은 부제), 안쪽 여백 |
| `EmptyState` | empty_state.dart | 빈 화면 · 안내 묶음: (강조 색 아이콘 40) · 제목(titleMedium) · 옅은 설명 · (버튼), 가운데 정렬. 인자는 모두 선택이라 제목만 주면 한 줄, 목록 · 카드 안이면 `compact: true` |
| `EmptyState.network` · `EmptyState.timeout` · `EmptyState.signIn` | empty_state.dart | 같은 모양의 "네트워크 연결이 필요해요"(와이파이 빗금 아이콘 + 다시 시도) · "응답이 너무 오래 걸려요"(모래시계 아이콘 + 다시 시도, 시간 초과) · "로그인이 필요해요"(자물쇠 아이콘 + 로그인) 안내. 문구는 ARB `stateNetwork*` · `stateTimeout*` · `stateSignIn*` |
| `LoadingIndicator` · `LoadingState` | loading_indicator.dart | 앱 전체의 불러오는 중 표시(강조 색 동그라미) 하나. 영역은 가운데 `LoadingState`(+문구), 버튼 · 줄 안은 `LoadingIndicator.small`. 화면 위에 얇게 깔아 자리를 비우지 않는 곳(곡 자세히 · 웹 페이지 화면)은 `LoadingBar`(2px 막대) |
| `AppBackButton` | back_button.dart | 위 막대 왼쪽 뒤로 가기 (기본은 화면 닫기) |
| `AppDivider` | app_divider.dart | 얇은 구분선 한 줄(윤곽 색) |
| `SectionTitle` | section_title.dart | 화면 · 시트 안 구역 제목(titleMedium). 화면은 좌우 여백 + 아래 틈, 시트는 `padded: false` |
| `ExpandableText` | expandable_text.dart | 긴 설명 글: n줄(기본 4)까지 보이고 넘칠 때만 "더 보기 / 접기" (영상 · 채널 설명) |
| `showConfirmDialog` | app_dialog.dart | 예 · 아니오 확인창 하나 (제목 · 설명 · 취소 | 확인). 지우기 · 되돌리기 앞은 모두 이것으로 — 화면마다 확인창을 따로 만들지 않는다 |
| `CoverEntry` (covers) | cover_entry.dart | 이미지를 정하는 줄 (지금 이미지 + "이미지 고르기 / 바꾸기"). 곡 · 앨범 · 재생목록 · 받기가 모두 같은 이미지 페이지(`showCoverEditor`)를 연다: 고르기 · 위치 · 기본으로 되돌리기(확인 후)는 그 페이지 안에서, 이미지가 없으면 확대 · 회전 · 적용은 숨는다 |
| `showAppMenu` · `AppMenuItem` | app_popup_menu.dart | 팝업 메뉴 (아이콘 + 글자, `destructive` 경고 색, `dividerBefore`, 색 견본용 `iconColor`, 고른 항목 `selected` 체크). 눌린 자리 또는 위젯 옆에 최상위 내비게이터로 연다 (곡 메뉴) |
| `AppSwitch` | app_switch.dart | 토글 (켜짐 = 강조 색) |
| `AppSlider` | app_slider.dart | 가는 막대 슬라이더 (가로 · 세로, 이퀄라이저) |
| `PinPad` | pin_pad.dart | PIN 입력 판 (입력 자리 점 + 숫자 키패드, 0 왼쪽 칸에 생체 버튼). 입력값은 밖에서 들고 있음 |
| `AppTextField` | app_text_field.dart | 라벨이 위에 붙은 둥근 입력칸 (폼). 글자는 세로 가운데. `maxLines`를 주면 여러 줄 |
| `SectionBlock` | section_card.dart | 긴 화면의 구역: 위 옅은 구분선 + 작은 제목(카드 면 없음). 영상 상세 · 받기 페이지 |
| `SectionCard` · `SettingRow` | section_card.dart | 설정 묶음(제목 + 구분선, 카드 면 없음) · 한 줄 |
| `SegmentedPills` · `StatusPill` | segmented_pills.dart | 하나 고르기 알약 묶음 · 상태 알약 |
| `AppDropdown` | app_dropdown.dart | 알약 드롭다운 (정렬 기준 고르기). 선택값 · 목록 · 문구는 밖에서 받음 |
| `ThemeSwatch` | theme_swatch.dart | 테마 프리셋 미리보기 동그라미 (다른 팔레트를 그리는 유일한 컴포넌트) |

Material 버튼 · AppBar · ListTile · Switch · Chip · Slider는 화면에서 직접 쓰지 않는다 (위 컴포넌트로 대체).

## 앱 틀 레이아웃
- `Scaffold(extendBody: true)`: 내용이 유리 미니 플레이어 · 탭 바 뒤로 흘러가며 흐리게 비친다.
- 탭 화면의 스크롤 목록은 아래 여백을 `MediaQuery.paddingOf(context).bottom`만큼 더 둔다.
- 유리(BackdropFilter)는 비용이 있으니 목록의 줄마다 쓰지 않는다 (카드 · 묶음 · 바에만).

## 아이콘
- 화면 · 컴포넌트는 `Icons.xxx`(Material)를 직접 쓰지 않고 `AppIcons.xxx`([lib/core/design/icons/app_icons.dart](../lib/core/design/icons/app_icons.dart))만 쓴다.
- 글리프는 Phosphor(MIT)의 둥글고 부드러운 선 아이콘이다. 재생 · 일시정지 · 이전 · 다음 · 좋아요 등 면이 필요한 곳은 Fill 폰트를 쓴다. 폰트는 `assets/fonts/phosphor/`(라이선스 포함).
- Phosphor 패키지(`phosphor_flutter`)는 현재 Flutter에서 컴파일되지 않아(`IconData`가 final) 폰트 파일만 가져오고 코드포인트는 `AppIcons`에 직접 적었다.
- 세트를 바꾸거나 직접 그린 아이콘 폰트로 교체할 때는 `AppIcons`의 정의와 폰트만 고치면 된다.

### OutlinedPanel
윤곽선이 있는 옅은 면(연한 면 색 + 윤곽선 + 작은 반경). 설정 줄 · 표를 한 칸으로 감쌀 때 쓴다. 화면에서 같은 `DecoratedBox(ShapeDecoration…)`를 직접 만들지 않는다 (`lib/core/design/components/outlined_panel.dart`).
