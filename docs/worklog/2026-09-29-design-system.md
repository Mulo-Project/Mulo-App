# 디자인 시스템 기초

> 점(도트) 모양은 사용자 피드백으로 글래스 스타일로 바뀜 (D-012, [MVP 화면 기록](2026-09-29-mvp-screens.md)). 토큰 · 테마 소스 구조는 그대로.

- 날짜: 2026-09-29
- 분류: 디자인 · 앱
- 상태: 완료
- 브랜치: `feature/design-system` (develop 합치기 전, 승인 대기)
- 상세 기능: 없음 (공통)

## 한 일
- 레퍼런스(검정 · 점 격자 · 글로우 카드 · 점 행렬 숫자, 팔레트 검정 · 바이올렛 · 라임 · 흰색)로 기본 테마 구성.
- `lib/core/design/`
  - tokens: `AppPalette`(색 · 글로우 그라데이션 3종, `derive` · `lerp`), `AppSpacing` · `AppRadii` · `AppMotion` · `AppSizes`, `AppTypography`
  - `AppThemeTokens`(ThemeExtension, copyWith · lerp), `buildAppTheme`, `contrast.dart`(대비 계산 · 보정)
  - `ThemeSource`: `DefaultThemeSource`(실제), `CustomThemeSource` + `CustomThemeStore`(메모리 구현만), `MoodThemeSource`(커버 아트 색 추출, 플레이어 미연결)
  - `ThemeController`(Riverpod): `apply(source)` · `reset()`, 늦게 끝난 추출 결과 버림. 전환 700ms 애니메이션
  - components: DotGridBackground, GlowCard, DotMatrixText, PillButton, CircleIconButton, DottedProgressArc · DottedProgressBar, MiniPlayerBar
- `lib/features/design_preview/`: 컴포넌트 전체 + "기본 / 대체 팔레트" 전환. 첫 화면으로 연결.  (→ 2026-10-01 테마 미리보기로 대체, D-030)
- 문서: [design-system.md](../design-system.md)

## 바꾼 설정
- `pubspec.yaml`: `flutter_riverpod ^3.4.3` 추가.

## 확인
- `flutter analyze` 0, `flutter test` 2개 통과(팔레트 전환, 대비 보정).
- `flutter build apk --debug` 성공, Android 에뮬레이터(API 37)에서 실행 확인.
- Windows 빌드는 Visual Studio 툴체인이 없어 못 함.

## 남은 일 · 질문
- 사용자 지정 테마 저장(shared_preferences)과 설정 화면.
- "곡 분위기 따라가기" 설정 분기 (D-005) — 나중에.
- Android 스플래시가 흰색이라 검정 테마와 어긋남 → 검정으로 바꿀지 질문 중.
