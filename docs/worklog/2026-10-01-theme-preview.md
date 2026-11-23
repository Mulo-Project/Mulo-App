# 테마 미리보기

- 날짜: 2026-10-01
- 분류: 앱 · 설정 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `feature/theme-preview` (`chore/server-url-dart-define` 위, PR #21 다음)
- 상세 기능: 테마 미리보기

## 한 일
- 설정 › 테마 카드 맨 위에 미리보기(`ThemePreview`: 카드 2장 · 곡 줄 · 버튼 · 미니 플레이어)를 넣었다. 색 · 화면 모드를 바꾸면 바로 반영된다 (D-030).
- 옛 디자인 미리보기 화면 · 라우트 · 설정의 진입 줄을 없앴다. "대체 팔레트" 토글도 사라졌다.
- 테스트: 디자인 미리보기 테스트를 설정 테마 미리보기 테스트로 바꿨다 (프리셋 변경 시 색 변화, 영어 문구).

## 바꾼 설정
- 새 패키지 없음. 문구(ko · en): `dp*` 16개 삭제, `settingsDesignPreview` → `settingsThemePreview`, `themePreviewSong` · `themePreviewArtist` 추가, `flutter gen-l10n` 재생성.
- 라우터에서 `Routes.designPreview` 삭제.

## 확인
- `flutter analyze` 0, `flutter test` 94개 통과, `flutter build apk --debug` 성공.

## 남은 일 · 질문
- 미리보기는 적용 중인 팔레트를 보여 준다. 저장 전 임시 보기가 필요하면 별도 결정이 필요하다.
