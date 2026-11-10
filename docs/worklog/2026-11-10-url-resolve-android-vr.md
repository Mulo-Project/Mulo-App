# 2026-11-10 · 주소 읽기와 android_vr 정리

## 질문
미리 듣기가 빨라진 게 android_vr 덕분인가, android_vr을 지워도 되나.

## 읽기 경로 (코드 기준)
| 대상 | 1순위 | 2순위(fallback) |
|---|---|---|
| 소리 주소 | `YoutubeExplodeEngine`(youtube_explode_dart, androidVr → androidSdkless) | yt-dlp 기본 클라이언트 → 실패하면 `player_client=android_vr` 재시도 |
| 영상 주소 | `YoutubeExplodeEngine` (15초 제한) | yt-dlp 기본 클라이언트 → android_vr 재시도 |
| 파일 받기 | 별개: 10MB 범위 요청 / 보관 받기는 8갈래 조각 | - |

- 근거: decisions.md D-062 (yt-dlp는 JS 실행기가 없으면 소리 형식을 못 주는 경우가 있어 실패했다).
- yt-dlp만 쓸 때 영상 주소는 기본 클라이언트로 17초(폰) 기록이 있다. 소리 주소는 숫자 기록 없음.
- android_vr 우선으로 yt-dlp 소리를 읽는 변경은 되돌렸다 (받기 느림의 원인이 아니었다).

## 확인된 것 / 안 된 것
- 확인: 받기가 빨라진 것은 범위 요청 때문(사용자 확인 "갑자기 엄청 빨라졌어").
- 미확인: 주소 읽기 시간, android_vr 제거 시 영향. 기기에서 아래 로그로 잰다.

## 재는 법 (debug 빌드, `adb logcat -s flutter` 에서 `MuloSearch` 검색)
- `explode 소리 읽음 NNNms` / `explode 소리 실패 …` : 1순위 경로 시간
- `explode 영상 읽음 …` : 영상 1순위
- `소리만 읽기 NNNms`, `영상만 읽기 NNNms` : yt-dlp 경로 전체 시간
- `yt-dlp NNNms 종료 코드 [… android_vr]` : android_vr 재시도가 탔는지

## 판단 기준
- explode 읽음이 대부분이면 yt-dlp의 android_vr은 거의 안 탄다 → 지워도 속도 영향 없음, 실패 대비만 줄어든다.
- `[… android_vr]` 줄이 자주 나오면 기본 클라이언트가 실패하고 있다는 뜻 → 유지.

## 기기 로그 결과 (2026-11-10, Android 실기기, debug)
한글이 `???`로 깨져 와서 줄 모양으로 짝지었다 (`explode 영상 읽음`, `explode 소리 읽음`).

| 경로 | 시간 | 표본 |
|---|---|---|
| explode 영상 읽음 | 2.1 ~ 3.2초 (예외로 14.7초 1번) | 6 |
| explode 소리 읽음 | 1.9 ~ 2.1초 | 4 |
| yt-dlp 호출 (클라이언트 지정 없음) | 3.0 ~ 4.6초 | 2 |
| yt-dlp 호출 `[android_vr]` | 19.1초 | 1 |

- youtube_explode_dart가 읽을 때 내부적으로 androidVr 클라이언트를 쓴다(D-062). 미리 듣기가 빨라진 쪽은 이 경로로 보는 게 맞다.
- yt-dlp의 `android_vr` 재시도는 이 표본에서 1번 탔고 19초였다. 그 호출 앞에 기본 클라이언트가 실패한 시간이 합쳐졌는지, 소리인지 영상인지는 로그만으로 알 수 없다(라벨에 -f가 없었다).
- 표본이 적다. 결론: 평소 속도는 explode가 정하고, yt-dlp의 android_vr은 드물게 타는 느린 fallback이다.
