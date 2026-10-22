# 미리 듣기 문제 해결 기록 (Android)

2026-10-06, 검색 결과 미리 듣기(D-061 ~ D-064)를 Android 기기에서 틀 때 겪은 문제와 고친 과정.
결정의 근거는 [decisions.md](decisions.md), 작업 기록은 [worklog/](worklog/README.md).

## 증상 한눈에
| 증상 | 까닭 | 고친 곳 |
|---|---|---|
| 미리 듣기가 "불러올 수 없어요"로 실패, yt-dlp가 형식을 못 줌 | JS 실행기(Deno 등)가 없으면 yt-dlp가 YouTube 오디오 형식을 못 준다 | D-062: `youtube_explode_dart`로 먼저 읽는다 |
| ExoPlayer가 DASH m4a 주소를 못 엶 (Source error) | Android 플레이어가 DASH m4a(분할 mp4)를 못 여는 일이 있다 | 오디오 형식 정책(`audio_format_policy.dart`): Android는 webm/opus 먼저, 안 열리면 다른 형식 주소로 이어서 시도 |
| 몇 초 듣다 끊기거나 HTTP 403 | `c=ANDROID` 주소는 PO 토큰이 없으면 첫 약 256KB(`bytes=0-262143`)만 206, 그 뒤 구간은 403 | D-064: visionOS 클라이언트 주소를 먼저 쓴다 |
| 주소는 읽혔는데 중간부터 막힘 | 맨 앞 구간만 받아 보고 "된다"고 판단하면 속는다 | 주소를 쓰기 전에 클라이언트별로 **중간 구간**을 실제로 요청해 보고 되는 것만 쓴다 (mid-range probe) |

## 1. DASH m4a와 ExoPlayer
- 검색 · 곡 정보는 형식이 필요 없어 잘 되지만, 재생 주소는 형식에 따라 열리는 곳이 갈린다.
- macOS(just_audio 자체 구현)는 webm/opus를 못 풀어서 m4a가 필요하고, Android는 DASH m4a를 못 여는 일이 있다. 그래서 **OS별 정책 한 곳**에서 정한다.
- 플레이어가 직접 못 열면(`PlayerException`) 앱이 HTTP로 받아 넘기는 `StreamAudioSource`(`_HttpRangeSource`)로 한 번 더 시도한다. 재생 중에 막혀도 같은 방식으로 이어서 튼다.
- 어떤 형식이든 재생은 되게: 주소가 안 열리면 다른 형식 주소(`AudioStream.fallbacks`)를 차례로 시도한다.

## 2. `c=ANDROID` 403 (PO 토큰)
- 이 PC에서 재현: `c=ANDROID` 주소에 `Range: bytes=0-262143`만 206, 다른 구간은 403. youtube_explode 자체 다운로드도 같은 곳에서 멈춘다. 기기 로그의 403이 이것이다.
- PO 토큰(Proof of Origin)이 없는 클라이언트는 첫 수백 KB만 열어 준다. 앞부분만 확인하면 정상으로 보이는 게 함정이다.
- 앱 중계는 끝을 안 정한 구간 요청도 403으로 막으므로 항상 약 10MB씩 구간을 정해 요청한다.

## 3. visionOS 클라이언트로 먼저 읽기
- yt-dlp 기본 클라이언트인 visionOS는 JS 실행기와 PO 토큰이 필요 없다. `YoutubeApiClient`로 직접 정의해 **가장 먼저** 쓴다.
- 같은 곡에서 중간 구간 · 끝 없는 구간 요청이 모두 206인 것을 확인했다.
- 안 되면 androidVr → androidSdkless 순서로 넘어간다. 주소를 만든 클라이언트(`c=`)별 user-agent로 요청한다.

## 4. 중간 구간 확인 (mid-range probe)
- 클라이언트마다 후보 주소를 만들고, 실제로 **곡 중간쯤의 구간**을 요청해 206이 오는 주소만 채택한다.
- 첫 구간만 열리는 주소(2번)를 걸러 내는 것이 핵심이다. 확인에 쓴 방식(앱의 HTTP)과 재생에 쓰는 방식이 같아야 결과를 믿을 수 있다.

## 다시 막힐 때 확인 순서
1. 실패 안내에 덧붙는 마지막 줄(`direct: … | app: … | probe`)로 어느 단계에서 막혔는지 본다.
2. 주소의 `c=` 값과 `Range` 요청 결과(206 / 403)를 본다.
3. 앞 구간만 되면 PO 토큰 문제다: 클라이언트 순서를 점검한다.
4. 형식이 문제면 `audio_format_policy.dart`를 본다.
5. 그래도 막히면 JS 실행기(QuickJS) 도입을 다시 검토한다 (D-062에서 보류).

## 이 기록과 함께 바뀐 것
- 미리 듣는 동안의 미니 플레이어(D-092)를 누르면 그 곡의 유튜브 상세 화면이 열린다. 막대를 눌러 · 끌어서 원하는 자리로 옮기는 건 상세 화면 · 검색 줄에서 한다 (D-065).
