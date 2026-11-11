# 검색 · 재생목록 곡 조회를 네이티브로 (2026-11-11)

## 배경
검색은 yt-dlp를 매번 띄워(`ytsearchN:`) 폰에서 수 초 걸리고, 다음 쪽은 앞쪽까지 처음부터 다시 받는다. 재생목록 곡 조회(`fetchInfo`)도 yt-dlp `--flat-playlist`. 재생 주소 읽기를 네이티브로 옮긴 것(#167, D-162)과 같은 방향으로, 읽기를 Kotlin에서 하고 Dart는 결과만 받는다. (Dart 라이브러리로 하는 방식은 사용자가 원치 않아 닫았다.)

## 변경
- 네이티브 `YoutubeBrowser`: InnerTube `search`(동영상 필터) · `browse`(`VL`+목록 id) 를 HttpURLConnection · org.json으로 부른다.
  - 검색: 같은 검색어의 다음 쪽은 continuation으로 이어 읽는다 (최근 3개 검색 기억, 같은 검색의 요청은 차례로).
  - 재생목록: continuation을 끝까지 따라가 모든 곡을 돌려준다 (최대 6000곡). 비공개 · 삭제 곡은 뺀다.
  - 응답을 못 읽으면 빈 결과가 아니라 예외 → Dart가 yt-dlp로 넘어간다.
- `YoutubeResolveChannel`에 `search` · `playlist` 메서드 추가 (채널 이름 `music_app/youtube_resolve` 그대로).
- Dart: `NativeYoutubeResolver.search/playlist`(MediaHit으로 변환), `YoutubeResolveEngine`이 유튜브 · 최신순 아님 검색과 `/playlist?list=` 주소를 먼저 네이티브에 묻고 실패하면 안쪽 엔진. 곡 하나 주소(`watch?v=…&list=…`)는 그대로 yt-dlp.
- 패키지 · Manifest 변경 없음. 로그: `adb logcat -s MuloNative` (`검색 쪽N …ms`, `재생목록 N곡 …ms`), `adb logcat -s flutter` (`[MuloSearch] 검색 …`).

## 한계 / 후속
- 이 환경에서는 YouTube에 연결할 수 없어 응답 모양은 기존 라이브러리 소스를 보고 맞췄다. 실기기 확인 필요.
- 검색 결과에는 올린 날이 없다 (정렬 최신순은 기존 yt-dlp). 설명은 앞부분.
- 곡 정보(`fetchInfo` 곡 하나) · 채널 정보 · 재생목록 *검색*은 아직 yt-dlp. 상세 화면은 이 중 곡 정보 · 채널이 yt-dlp 줄을 선다 → 다음 후보.

## 확인 필요
- PC: `flutter analyze`, `flutter test`, Android 빌드(Kotlin 컴파일은 이 환경에서 못 했다).
- 기기: 검색 첫 쪽 · 다음 쪽 시간, 한글 검색어 결과, 재생목록 가져오기(곡 수가 yt-dlp와 같은지, 시간), 라이브 방송이 목록에 어떻게 나오는지.
