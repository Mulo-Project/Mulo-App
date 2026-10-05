# 유튜브 분류 읽기 · 검색창 유튜브 표시 정리

- 날짜: 2026-10-06
- 분류: 앱 · 디자인
- 상태: 완료
- 브랜치 · 커밋: `feature/search-youtube-category`
- 상세 기능: 키워드 검색 (#2) · 공통 작업 (디자인 시스템)

## 한 일
- 유튜브가 영상에 붙인 분류(yt-dlp `categories`)를 `MediaHit.categories`로 읽는다 (로컬 · 서버 엔진). 검색 결과 줄에 분류 이름(예: 음악)을 함께 보인다. 결정은 D-057.
- 검색창의 유튜브 표시(`YoutubeMark`)를 `CustomPainter`로 다시 그렸다. 삼각형이 상자를 꽉 채우던 것을 절반 높이 둥근 삼각형으로 줄여 깔끔하게.

## 바꾼 설정
- 없음 (새 패키지 · 에셋 없음). ARB에 `videoCategory`(select) 추가. `windows/flutter/generated_plugin*` 변경분은 무관해 포함하지 않았다.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (엔진 파싱 3건 · 화면 1건 추가).
- yt-dlp를 이 PC에 설치하지 않아 실제 유튜브 응답으로는 확인하지 못했다. `categories`는 yt-dlp 정보 JSON에 들어 있는 필드이고, 목록(`--flat-playlist`) 항목에는 없다는 점은 yt-dlp 동작에 따른 것이다.

## 남은 일 · 질문
- 유튜브 분류는 `Music` 등 큰 갈래뿐이라 장르(록 · 힙합)로는 못 쓴다. 장르가 필요하면 제목 · 태그(`tags`) 기반 추정이나 YouTube Music 메타데이터가 필요하다.
- 검색 목록에 분류를 보이려면 목록 항목마다 정보를 더 받아야 해 느려진다. 필요하면 "보이는 항목만 뒤에서 채우기"를 따로 검토한다.
