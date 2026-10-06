# 장르별 기본 색 · 받을 때 색 고르기

- 날짜: 2026-10-06
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/genre-default-color` (#59 위)
- 상세 기능: 다운로드 팝업 (#7)

## 한 일
- 받기 팝업에 색 고르기를 넣고, 장르 기본 색을 따라가며 "이 장르의 기본 색으로 저장"을 켤 수 있다 (D-066).
- 색은 `DownloadRequest.color` → `DownloadItem.color`로 이어진다. 보관함 장르 타일에 기본 색을 보인다.

## 바꾼 설정
- 없음 (새 패키지 · 에셋 없음). ARB에 `downloadColorSaveForGenre` 추가.

## 확인
- `flutter analyze` 0, `flutter test` 통과.

## 남은 일 · 질문
- 받기가 끝나 곡이 만들어지는 코드가 아직 없어서, 받은 곡의 커버 색 적용은 그때 `DownloadItem.color`를 읽어 붙인다.
