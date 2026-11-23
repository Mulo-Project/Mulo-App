# 화면 모드 다크 · 라이트

> 이후 사용자 요청으로 '시스템' 선택을 없애고 기본 다크로 바꿈 (D-018, 브랜치 `fix/settings-theme-mode-dark-default`).

- 날짜: 2026-09-30
- 분류: 디자인 · 앱
- 상태: 완료 (merge 대기)
- 브랜치: `feature/settings-brightness` (`fix/design-glass-scope` 위)
- 상세 기능: 화면 모드 (다크 · 라이트) — 새로 추가

## 한 일
- 사용자 요청 (D-016): 설정 › 테마 › 화면 모드 시스템 · 다크 · 라이트, 저장.
- `AppPalette.defaultLight` · `baseFor` · `accentContrastFor` · `brightness`, 라이트 바탕 추가.
- `ThemeSource.resolve(Brightness)`로 변경 (프리셋 · 사용자 지정 · 곡 분위기 모두).
- `ThemeController`: 다크 · 라이트 팔레트 동시 보관, `selectMode`, 모드 저장 · 복원.
- 앱: `theme` / `darkTheme` / `themeMode`, 상태 표시줄 아이콘 밝기 자동.
- 라이트에서 커버 음표 · 스위치 손잡이 색 수정 (`onGlow`).
- 설정 테마 색 미리보기도 현재 모드 팔레트로.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (모드 선택 · 저장 · 복원, 모든 프리셋 라이트 대비 3:1, 위젯 라이트 ↔ 다크).
- 라이트 스크린샷: 보관함 · 재생목록 · 설정 · 플레이어.

## 남은 일
- Android 시작 화면은 검정 고정.
