# 테마 색 프리셋

- 날짜: 2026-09-29
- 분류: 디자인 · 앱
- 상태: 완료 (merge 대기)
- 브랜치: `feature/settings-theme-presets` (`ui/mvp-screens` 위 — PR #3 다음에 합친다)
- 상세 기능: 테마 색 고르기 (새로 추가)

## 한 일
- 사용자 요청 "테마를 여러 색깔로" → 프리셋 8개 `ThemePreset` (바이올렛 기본 · 코랄 · 오션 · 포레스트 · 선셋 · 로즈 · 골드 · 아이스). D-013.
- `ThemeController`: `selectPreset`(적용 + 저장), 시작 시 저장 값 복원, `reset`은 고른 프리셋으로. `DefaultThemeSource` 제거(바이올렛 프리셋이 기본).
- 저장소 `ThemePreferenceStore` → `SharedPrefsThemePreferenceStore` (`theme.preset`). 테스트는 메모리 구현으로 교체.
- 컴포넌트 `ThemeSwatch` (유리 동그라미 + 강조 색 점, 선택 시 테두리 · 체크).
- 설정 › 테마 색: 기본/코랄 선택 → 프리셋 8개 격자. ARB에 프리셋 이름(ko/en).
- 테스트: ThemeController 5개 (기본값, 저장, 복원, 모든 프리셋 대비 7:1, reset).

## 바꾼 설정
- `pubspec.yaml`: `shared_preferences ^2.5.5`

## 확인
- `flutter analyze` 0, `flutter test` 통과, 설정 전체 스크린샷 확인.

## 남은 일
- 곡 분위기 따라가기 스위치 연결(D-005)은 플레이어 기능 연결 때.
