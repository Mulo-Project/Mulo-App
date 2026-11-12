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

## 추가 (속도)
- 연결 미리 열기: 검색 화면을 열 때 `DownloaderEngine.warmUp()` → 네이티브 `YoutubeBrowser.warmUp()`(`www.youtube.com/generate_204` HEAD)이 DNS · TCP · TLS를 미리 해 둔다. 응답을 끝까지 읽고 `disconnect()`를 부르지 않아 연결이 풀로 돌아가 다음 요청이 재사용한다 (새 라이브러리 없이 Android HttpURLConnection의 연결 풀 사용).
- 다음 쪽 미리 받기: 한 쪽을 돌려준 뒤 뒤에서 다음 쪽을 같은 검색 세션에 받아 둔다 (한 번에 하나, 실패는 무시하고 그 쪽을 부를 때 다시 읽는다).
- 가져오기 화면을 열 때도 같은 미리 열기를 부른다.
- 응답 필드 줄이기는 하지 않는다 (`prettyPrint=false`만).
- 로그: `연결 미리 열기 …ms`, `다음 쪽 미리 받기 …ms`.

## Dart 구현 걷어내기 (같은 PR)
사용자 요청: Dart에 구현된 YouTube 기능을 네이티브로 옮기고 Dart 구현 · 폴백은 지운다.
- 채널 검색 · 채널 상세(배너 · 소개 · 구독자 수) · 채널 id 알아내기 · 채널 RSS 피드: Dart `ExplodeChannelSearcher` · `YoutubeFeedClient`를 지우고 네이티브 `YoutubeChannels`(+`YoutubeChannelParsers`, Kotlin 단위 테스트)로. Dart는 `NativeYoutubeChannels`가 요청 · 모델 변환만.
- 재생목록 *검색*: 네이티브 `YoutubeBrowser.searchPlaylists`(옛 `playlistRenderer` · 새 `lockupViewModel` 둘 다), Dart의 youtube_explode_dart 폴백 삭제. 못 읽거나 비면 yt-dlp.
- 구글 YouTube Data API(내 재생목록 · 구독 목록 · 채널 재생목록): 네이티브 `GoogleApi` + `GoogleApiChannel`(`music_app/google_api`)이 쪽 넘기기 · 오류 가르기 · 항목 만들기. 로그인(토큰)은 Dart 플러그인 그대로, 진행 수는 네이티브가 `progress`로 알린다. Dart 파서 · HTTP 삭제.
- 상세 화면: 곡 정보를 네이티브 `YoutubeResolver.info`(InnerTube `player`의 videoDetails · microformat · captions)로 먼저 읽고, 채널 이미지 · 구독자 수도 네이티브(`YoutubeChannels.info`). 좋아요 수 · 공동 작업자 · 앨범은 `fetchFullInfo`(yt-dlp)로 화면을 띄운 뒤 뒤에서 채운다 (`MediaDetailCubit`).
- `youtube_explode_dart` 의존성 제거 (pubspec). 영상 id 파싱은 작은 순수 함수 `youtubeVideoIdOf`.
- Kotlin 테스트용 `org.json:json` testImplementation 추가 (build.gradle.kts).

## yt-dlp 로컬 엔진도 네이티브로 (같은 PR, 사용자 "다 옮겨")
결정 D-164: Android만 남기고 데스크톱용 Dart yt-dlp 엔진과 데스크톱 OAuth를 지운다.
- 네이티브 `YtDlpEngine`(Kotlin, 채널 `music_app/ytdlp_engine`): 검색(다른 사이트 · 최신순 키) · 재생목록 검색 · 곡/재생목록 정보 · 채널 정보 · 소리/영상 주소(기본 → `android_vr` 재시도) · 오디오 언어 · 자막(언어 고르기 + VTT 읽기) · 영상 파일 저장(`saveVideo`).
  - `YtDlpParsers`: yt-dlp JSON → 값, `-f` 선택자(미리 듣기 · 화면용 · 저장용 mp4/webm), 오류 가르기, 자막 언어 고르기, VTT 파싱. 모두 순수 함수.
  - `ExecGate`: 한 번에 하나씩, 우선순위(소리 0 → 영상 1 → 나머지 2) · 같은 그룹의 새 요청이 오면 대기 중인 예전 요청이 빠진다 (예전 Dart `_ExecGate`와 같다). 60초 안에 안 끝나면 yt-dlp를 끊고 `timeout`. 영상 저장은 줄 밖에서 따로(30분 제한).
  - 실행기 `YtDlpRunner`: full은 `YtDlpChannel`(youtubedl-android)이 구현, lite는 `available=false`. 예전 `music_app/ytdlp`의 `run`/`cancel`은 없앴다 (버전 · 업데이트 · 되돌리기만 남음).
- Dart: `NativeYtDlp`(채널 호출 · 오류 코드 → `EngineFailure`)와 `YtDlpEngine`(받은 맵 → 모델)만 남았다. `LocalEngine` · `audio_format_policy`의 yt-dlp 선택자 · `parseVtt` · `avatarUrl` 삭제. `YtDlpVideoSaveRepository`는 `fetch`(네이티브 `saveVideo`)를 부르고, 형식별(mp4 · webm) 선택은 네이티브가 확장자로 가른다.
- 데스크톱 삭제: `YtDlpManager`는 Android만, `LoopbackGoogleAuth`(OAuth 브라우저 로그인)와 `MULO_GOOGLE_DESKTOP_*` 빌드 값 삭제 (`AuthStore`는 `auth_store.dart`로 분리). `docs/google-login-setup.md` 갱신.
- 테스트: Dart `LocalEngine` 테스트(7개 파일)는 Kotlin `YtDlpParsersTest` · `YtDlpEngineTest` · `ExecGateTest`로 옮기고, Dart는 `yt_dlp_engine_test.dart`(채널 값 전달 · 모델 담기 · 오류 코드 · Routing · 영상 저장)만.

## SoundCloud 아바타도 네이티브로
`SoundcloudAvatarEngine`(Dart가 아티스트 페이지 HTML을 받아 `og:image` 읽기)을 지웠다. 네이티브 `YtDlpEngine.channel`이 SoundCloud 주소에서 프로필 이미지가 비면(또는 yt-dlp가 실패해도) 페이지 앞 200KB를 읽어 채운다 (`YtDlpParsers.soundcloudAvatarFromHtml`). 서버 모드(서버 미배포)에서는 이 보충이 없다.

## 아직 Dart에 남은 것
- 구글 로그인(Android `google_sign_in` 플러그인 + 토큰 보안 저장소): 이미 플러그인(네이티브)을 부르는 얇은 감싸기다. 네이티브로 다시 쓰려면 Credential Manager · Google Identity 의존성을 새로 넣어야 해서 별도 결정이 필요하다.

## 한계 / 후속
- 이 환경에서는 YouTube에 연결할 수 없어 응답 모양은 기존 라이브러리 소스를 보고 맞췄다. 실기기 확인 필요.
- 검색 결과에는 올린 날이 없다 (정렬 최신순은 기존 yt-dlp). 설명은 앞부분.

## 확인 필요
- PC: `flutter pub get`(youtube_explode_dart 제거로 pubspec.lock 갱신), `flutter analyze`, `flutter test`, Android 빌드와 `./gradlew testDebugUnitTest`(Kotlin 컴파일 · 테스트는 이 환경에서 못 했다).
- 기기: 검색 첫 쪽 · 다음 쪽 시간, 한글 검색어 결과, 재생목록 가져오기(곡 수가 yt-dlp와 같은지, 시간), 라이브 방송이 목록에 어떻게 나오는지.
- 기기(yt-dlp 엔진): SoundCloud 검색 · 곡 정보, 자막 받기(가사), 오디오 언어 목록, 영상 mp4/webm 저장과 진행률, lite 빌드에서 서버로 넘어가는지. 로그 `adb logcat -s MuloNative` (`yt-dlp …ms 종료`).
