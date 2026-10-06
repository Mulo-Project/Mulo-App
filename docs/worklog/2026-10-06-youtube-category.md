# 유튜브 분류 읽기 · 검색창 유튜브 표시 정리

- 날짜: 2026-10-06
- 분류: 앱 · 디자인
- 상태: 완료
- 브랜치 · 커밋: `feature/search-youtube-category`
- 상세 기능: 키워드 검색 (#2) · 공통 작업 (디자인 시스템)

## 한 일
- 유튜브가 영상에 붙인 분류(yt-dlp `categories`)를 `MediaHit.categories`로 읽는다 (로컬 · 서버 엔진). 검색 결과를 분류로 거르는 필터는 곡마다 정보를 읽어야 해서 느려져 두지 않는다 (D-057).
- 검색 결과 제목 아래에 정렬 팝업(관련도 · 인기순 · 최신순 · 짧은 순 · 긴 순 · 제목순). 최신순은 yt-dlp 날짜 순 검색(`ytsearchdate`)으로 다시 찾는다.
- 더 보기 버튼을 무한 스크롤로 바꿨다 (맨 아래 줄이 보이면 다음 쪽).
- 검색창의 유튜브 표시(`YoutubeMark`)를 `CustomPainter`로 다시 그렸다. 삼각형이 상자를 꽉 채우던 것을 절반 높이 둥근 삼각형으로 줄여 깔끔하게.
- `AppDropdown` 메뉴 글자를 `Flexible` + 말줄임으로.

## 바꾼 설정
- 없음 (새 패키지 · 에셋 없음). ARB에 `videoCategory`(select) 추가. `windows/flutter/generated_plugin*` 변경분은 무관해 포함하지 않았다.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (엔진 파싱 · 최신순 검색 · 정렬 · 무한 스크롤 · 화면 테스트).
- yt-dlp를 이 PC에 설치하지 않아 실제 유튜브 응답으로는 확인하지 못했다. `ytsearchdate` 접두사는 yt-dlp가 지원하는 검색 방식이다.

## 남은 일 · 질문
- 분류로 거르기가 꼭 필요하면 서버 검색 응답에 `categories`를 넣는 방법이 가장 빠르다.
