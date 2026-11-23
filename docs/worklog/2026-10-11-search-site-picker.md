# 검색창 사이트 선택 · 링크 붙여넣기

- 날짜: 2026-10-11
- 분류: 앱
- 상태: 진행 중 (PR 확인 대기)
- 브랜치 · 커밋: `feature/search-site-picker`
- 상세 기능: 키워드 검색 (#2), URL로 곡 정보 불러오기 (#1)

## 한 일
- [D-097](../decisions.md): 검색 대상을 YouTube · SoundCloud로 나누고, 검색창 앞은 사이트 고르기 · 뒤는 검색 실행 버튼.
- 검색 시작 화면에 "링크 붙여넣기" 버튼: 클립보드의 링크를 넣고 곡 정보를 불러온다.
- `AppSearchField`에 `leading` 추가, `SoundcloudMark`(공식 아이콘 모양) 추가.

## 바꾼 설정
- pubspec · Gradle · Manifest: 변경 없음. ARB: 사이트 이름 · 붙여넣기 문구 추가, `sourceWeb` · `searchHintWeb` 제거.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과.

## 남은 일 · 질문
- 최신 yt-dlp(2026.08.19)에는 `ytsearchdate`가 보이지 않아 유튜브 최신순이 실제로 되는지 기기 확인 필요.
