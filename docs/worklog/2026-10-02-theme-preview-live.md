# 테마 미리보기: 실제 화면 둘러보기

- 날짜: 2026-10-02
- 분류: 앱 · 설정 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `ui/theme-preview-feedback` (`feature/home-stats-feedback` 위)
- 상세 기능: 테마 미리보기

## 한 일
- 피드백: 미리보기를 설정의 별도 항목으로 두고, 기존 페이지들을 오가며 테마를 확인한 뒤 설정할 수 있어야 한다.
- 설정 › 테마의 "테마 미리보기" 항목을 누르면 홈으로 이동하고, 탭 바 위에 `ThemePreviewBar`(화면 모드 · 색 · 취소 · 적용)가 뜬다. 샘플 카드 대신 실제 탭 화면에 시험 테마가 적용된다.
- `ThemeCubit`: `previewing` 상태, `beginPreview` · `previewPreset` · `previewMode`(저장 안 함), `applyPreview`(저장) · `cancelPreview`(시작 전 테마로 복귀).
- 샘플 미리보기 화면 · 위젯(`ThemePreviewScreen`, `ThemePreview`) 삭제.
- 테스트: 탭을 오가도 시험 테마 유지 · 취소 시 복귀 · 적용 시 유지.

## 바꾼 설정
- 새 패키지 없음. 문구: `themePreviewSong` · `themePreviewArtist` 삭제, `themePreviewHint` · `themePreviewApply` 추가, 설명 문구 수정.

## 확인
- `flutter analyze` 0, `flutter test` 통과.
