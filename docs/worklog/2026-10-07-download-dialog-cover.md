# 받기 팝업 커버 · 취소 확인

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료 (merge 대기)
- 브랜치 · 커밋: `feature/download-dialog-cover`
- 상세 기능: 다운로드 팝업 · 커버 이미지

## 한 일
- 받기 팝업: 유튜브 썸네일을 기본 커버로 보여 주고, "바꾸기"로 기존 커버 고르기(기기 · 웹 · 확대 · 위치)를 쓴다. "기본으로"로 썸네일로 되돌린다.
- 받기 팝업에 "취소" 버튼, 받는 곡 취소 시 확인 대화상자.
- 웹 커버 오프라인 캐시(`lib/core/cache/cached_web_image.dart`): 첫 표시 때 작은 사본을 캐시 폴더에 저장.
- `DownloadRequest` · `DownloadItem`에 `cover` 추가. 대기열 타일은 고른 커버로 그린다.
- 결정: D-069.

## 바꾼 설정
- 없음 (pubspec 변경 없음, `crypto` · `path_provider` 기존 의존성 사용). 문구 6개 추가(ARB).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과.

## 남은 일 · 질문
- 받기가 끝나 곡을 만들 때 `DownloadItem.cover`를 곡 커버로 붙이는 부분은 엔진 연결(#65)과 함께 이어 붙인다.
