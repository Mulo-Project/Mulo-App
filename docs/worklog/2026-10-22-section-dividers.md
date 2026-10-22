# 영상 상세 · 받기 페이지 섹션 구분

- 날짜: 2026-10-22
- 분류: UI
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `ui/section-dividers` (`feature/youtube-audio-language` 위)
- 상세 기능: 검색 (영상 상세), 다운로드 (받기 페이지)

## 한 일
- 공통 `SectionBlock`(위 옅은 구분선 + 작은 제목, 카드 면 없음)을 만들어 영상 상세(미리 듣기 · 정보 · 설명)와 받기 페이지(기본 정보 · 색 · 저장 · 가사)에 적용.

## 바꾼 설정
- ARB 문구 3개 추가(`mediaDetailSectionPreview` · `mediaDetailSectionInfo` · `downloadSectionInfo`). pubspec · Gradle · Manifest 변경 없음.

## 확인
`flutter analyze` 경고 0, `flutter test` 전체 통과.

## 남은 일 · 질문
- #116(`download_dialog.dart` 수정)과 같은 파일을 건드려 둘 중 나중에 합칠 쪽에서 충돌이 날 수 있다.
