# Mulo (뮤로)

유튜브 등에서 음원을 받아 저장하고, 같은 앱에서 바로 재생하는 **한국어 음악 앱**입니다.
화면은 Flutter, 재생은 Android 네이티브(Media3)가 맡아 앱을 닫아도 끊기지 않습니다.

<!-- 앱 아이콘 자리: 아이콘이 정해지면 여기에 넣는다 (예: <img src="docs/images/icon.png" width="96">) -->

> **개인 사용 목적**(저작권법 제30조 사적 이용을 위한 복제 범위)으로 만든 앱입니다.
> 이 저장소에는 음원 파일이나 저작권 있는 곡 주소를 넣지 않습니다.

| | |
|---|---|
| 패키지 | `com.mulo.app` |
| 지원 | **Android** (지금 집중하는 대상). Windows · iOS는 나중에 |
| 모드 | 로컬 모드 (기기 안에서 검색 · 받기). 서버 모드는 서버 배포 뒤에 |
| 언어 | 한국어 (기본) · 영어 |

<!-- 스크린샷 자리: 홈 · 플레이어 · 검색/받기 · 가사 화면을 docs/images/ 에 넣고 아래처럼 나란히 둔다
| 홈 | 플레이어 | 검색 · 받기 | 가사 |
|---|---|---|---|
| ![](docs/images/home.png) | ![](docs/images/player.png) | ![](docs/images/search.png) | ![](docs/images/lyrics.png) |
-->

## 한눈에 보기

| 영역 | 요약 |
|---|---|
| 검색 | 유튜브 · 사운드클라우드 키워드 검색, 영상 · 채널 · 재생목록 탭, 받기 전 미리 듣기 |
| 받기 | 음원(m4a · opus · mp3) 또는 영상(mp4 · webm)으로 저장. 이어받기, 대기열, 알림 |
| 불러오기 | 재생목록 주소 · 키워드로 가져오기, 구글 로그인으로 내 재생목록 · 구독 채널 가져오기 |
| 구독 | 구독 채널의 새 영상을 주기적으로 확인해 알림, 알림에서 바로 받기 |
| 재생 | Media3(ExoPlayer) 네이티브 재생 서비스. 앱을 닫아도 계속, 셔플 · 반복 · A-B 반복 · 배속 · 이퀄라이저 |
| 영상 | 소리와 영상을 한 시계로 재생, 작은 창(PiP) |
| 가사 | 파일 안 가사, 웹 검색으로 가져오기, 싱크 맞추기, 화면 위 가사 |
| 보관함 | 곡 · 앨범 · 아티스트 · 장르, 재생목록, 커버 꾸미기. **파일 태그가 원본** |
| 홈 · 설정 | 청취 통계, 테마 · 다크 모드, 앱 잠금(PIN · 생체 인증) |

**쓰는 기술 한 줄 요약**: 화면은 Flutter(flutter_bloc · get_it · drift), 재생 · 유튜브 주소 읽기 · 태그 쓰기는 Kotlin 네이티브, 받기와 변환은 자체 구현 + yt-dlp · ffmpeg(full 빌드).

---

# 상세 설명

> 아래는 코드와 `docs/`를 기준으로 쓴 내용입니다. 세부 결정 이유는 [docs/decisions.md](docs/decisions.md)에 있습니다.

## 1. 쓰는 기술 · 엔진

| 하는 일 | 쓰는 것 |
|---|---|
| 화면 · 상태 | Flutter, flutter_bloc(Cubit/Bloc), go_router, get_it |
| 로컬 DB | drift(SQLite). 곡 · 커버 · 가사 · 재생 기록 · 재생목록 등 |
| 설정값 | shared_preferences (보안 값은 flutter_secure_storage) |
| 재생 (Android) | Media3 ExoPlayer 1.7.1 + media3-session, HLS · DASH 지원. Kotlin `PlaybackHub` · `MuloPlaybackService` |
| 재생 (그 밖의 OS) | just_audio 기반으로 같은 약속을 흉내 냄 (지금은 Android가 목표) |
| 유튜브 주소 · 검색 · 재생목록 | 네이티브 InnerTube 호출 (Kotlin, 외부 라이브러리 없이 HttpURLConnection) |
| 받기 · 변환 | 스트림 주소를 직접 받기, 변환은 ffmpeg, 실패 시 yt-dlp (full 빌드는 youtubedl-android 0.18.1) |
| 태그 쓰기 · 읽기 | ffmpeg 기반 네이티브, 형식별 함수(mp3 · ogg/opus · mp4 · webm · m4a) |
| 구글 계정 | google_sign_in (로그인) + YouTube Data API v3 (네이티브 읽기) |
| 백그라운드 확인 | WorkManager 주기 작업 |
| 글꼴 · 아이콘 | Pretendard, Phosphor |

모든 외부 서비스 호출은 "네이티브가 먼저, 안 되면 yt-dlp" 순서입니다. 네이티브가 응답 모양을 못 읽으면 빈 결과를 돌려주지 않고 오류를 던져 yt-dlp로 넘어갑니다.

## 2. 검색

- **키워드 검색**: 유튜브는 네이티브 `search` API(WEB 클라이언트)로 영상 · 채널 · 재생목록 필터별로 읽습니다. 다음 쪽은 continuation으로 이어 읽고 최근 검색 몇 개만 기억합니다. 날짜순 정렬도 지원합니다.
- **사운드클라우드**는 yt-dlp(`scsearch`)로 검색합니다. 그 밖의 사이트는 주소를 붙여 넣어 받습니다.
- 검색 결과는 정렬 · 무한 스크롤이 되고, 결과를 눌러 상세(영상 · 채널)를 볼 수 있습니다. 시간이 너무 걸리면 짧은 안내 문구가 나옵니다.
- 엔진은 `RoutingDownloaderEngine`이 고릅니다: 로컬(yt-dlp 가능) → 서버 → 둘 다 없으면 "엔진 없음" 안내. 지금은 서버가 없어 로컬만 씁니다.

## 3. 미리 듣기 · 스트리밍

- 곡 주소는 `YoutubeResolver`가 InnerTube `player` API를 클라이언트(visionOS → android_vr → android) 순서로 불러 읽습니다. 파일 가운데 구간을 실제로 요청해 보고(probe) **열리는 주소만** 사용합니다.
- 소리는 4MB 구간(Range)으로 나눠 요청하는 `ChunkedHttpDataSource`로 읽어, 유튜브가 긴 연결 속도를 깎아도 끊기지 않게 합니다.
- 들은 부분은 임시 저장소(`StreamCache`)에 쌓여 같은 곡을 다시 들으면 네트워크 없이 재생합니다. 용량 한도는 설정에서 고르고(기본 500MB) 넘으면 오래된 것부터 지웁니다.
- 소리 언어(다국어 트랙)를 고를 수 있고, 영상은 화질을 고르거나 자동으로 정합니다.
- 상세 화면에서 **저장한 음원**으로 고르면 임시 저장이 아니라 앱 안에 남겨 두고 바로 들을 수 있습니다.

## 4. 받기 (다운로드)

1. 받기 팝업에서 제목 · 아티스트 · 앨범 · 장르 · 커버 · 담을 재생목록을 정합니다.
2. 미리 듣기와 **같은 주소 해석기**로 오디오 스트림 주소를 읽고, 구간 요청(HTTP Range)으로 임시 파일에 받습니다. 주소가 열리지 않으면 대체 주소를 차례로 씁니다.
3. 저장 형식에 따라 처리합니다.
   - `mp3`: ffmpeg(libmp3lame, 192kbps)로 변환
   - `opus`: 받은 원본 그대로 저장
   - `m4a`: 변환 없이 그대로 저장
   - 음질은 고르지 않고 항상 원본 기준 최고입니다. 변환기가 없거나 실패하면 원본 그대로 저장해 곡을 잃지 않습니다.
4. 제목 · 아티스트 · 앨범 · 장르 · 가사 · 커버(와 커버 출처 · 색 같은 부가 정보)를 **파일 태그로 씁니다**. 형식별 규칙은 네이티브의 형식별 함수가 각자 갖고, Dart는 형식을 모릅니다.
5. 완료되면 보관함 DB에 기록하고 알림을 띄웁니다. 이미 받은 곡은 건너뜁니다.

받기 대기열은 저장되어 앱을 다시 켜도 이어지고, 일시정지 · 취소 · 이어받기(형식이 같을 때 Range로 이어서)를 지원합니다. 받는 속도와 진행은 알림에 표시됩니다 (포그라운드 서비스).

**영상 저장**: mp4(H.264 + AAC) 또는 webm(VP9 + Opus). 네이티브 `NativeVideoSaver`가 영상 · 소리 주소를 읽어 받고 ffmpeg로 **다시 인코딩 없이** 합칩니다. yt-dlp는 주소는 찾아도 받을 때 403이 나는 경우가 있어 이 방법을 먼저 쓰고, 안 되면 yt-dlp로 넘어갑니다.

**기기 안에서 받을 수 있는 이유**: full 빌드에는 yt-dlp(파이썬)와 ffmpeg가 APK에 들어 있습니다. lite 빌드에는 없어 서버 모드만 쓸 수 있습니다.

## 5. 채널 · 재생목록 불러오기

**재생목록 곡 목록**
- 재생목록 주소를 붙여 넣거나 키워드로 검색해서 가져옵니다.
- 곡 목록은 네이티브 `browse` API의 continuation을 끝까지 따라가 모두 읽습니다 (한 번에 약 100곡, 최대 60쪽 = 6000곡). 못 읽으면 yt-dlp로 대신합니다.
- 가져오는 중에는 진행이 보이고, 이미 있는 곡은 건너뜁니다.

**내 재생목록 · 구독 채널 (구글 로그인)**
- 설정에서 로그인 버튼을 눌렀을 때만 로그인합니다. 로그인(토큰 얻기)은 `google_sign_in`이 하고, 읽기는 네이티브 `GoogleApi`가 **YouTube Data API v3**(`youtube.readonly` 범위)로 쪽을 끝까지 읽습니다.
- 내 재생목록, 구독 채널 목록, 채널의 재생목록을 가져옵니다. 채널이 없는 계정은 빈 목록으로 보여 줍니다.
- 오류는 `unauthorized` · `no_channel` · `network` · `timeout` · `failed`로 나눠 안내하고, API 한도나 사용 설정 문제는 별도 문구로 알려 줍니다.
- 로그인에는 `MULO_GOOGLE_SERVER_CLIENT_ID`가 필요합니다. 설정은 [docs/google-login-setup.md](docs/google-login-setup.md). OAuth 앱이 "테스트 중"이면 등록한 테스트 사용자만 로그인할 수 있습니다.

**채널 검색 · 상세**
- 채널 검색은 네이티브 `search` API의 채널 필터를 씁니다.
- 채널 상세(배너 · 로고 · 구독자 수 · 소개)는 채널 페이지를 읽어 해석합니다. 채널 id는 주소에서 알아냅니다.
- 채널 정보 시트에서 배너 · 구독자 수 · 소개 전체를 보여 주고, 구독 채널로 등록할 수 있습니다.

## 6. 구독 채널 새 영상 알림

- 구독한 채널 목록은 앱이 저장하고, 확인에 필요한 값은 SharedPreferences에 보관해 앱이 꺼져 있어도 읽습니다.
- WorkManager 주기 작업(`NewVideoWorker`)이 채널 RSS(`feeds/videos.xml`)를 읽어, 기준 시각 이후에 올라온 영상마다 알림을 띄웁니다. 확인 주기는 기본 3시간이고 1 ~ 24시간 사이에서 고릅니다.
- 채널마다 유튜브 분류(카테고리) 조건을 걸 수 있고, 조건이 있으면 새 영상마다 분류를 읽어(한 번에 최대 10개) 맞는 것만 알립니다. 분류를 못 읽으면 알립니다.
- 이미 알린 영상은 다시 알리지 않습니다. 실패한 채널은 다음 주기에 다시 보고, 실패 수는 설정 화면에 보입니다.
- 알림의 "바로 받기" 버튼으로 앱에서 받습니다 (워커가 직접 받지는 않습니다).

## 7. 재생

- **네이티브가 쥐는 것**: 재생 엔진, 미디어 세션, 알림, 포그라운드 서비스, 대기열, 곡 넘김, 셔플 · 반복. Dart는 명령을 보내고 결과를 비춥니다. 자세한 약속은 [docs/native-playback.md](docs/native-playback.md).
- 앱을 닫아도 재생이 이어지고, 프로세스가 죽어도 저장된 대기열로 블루투스 · 이어폰 버튼에서 이어 재생합니다.
- 알림 · 잠금화면 조작, 알림 좋아요 버튼, 곡 정보 숨기기(알림에 제목 가림).
- 셔플(켜면 지금 곡을 맨 앞에 두고 섞고, 끄면 원래 순서로), 반복(끄기 · 전체 · 한 곡), 대기열 편집(다음에 재생 · 맨 뒤에 추가 · 빼기 · 옮기기).
- A-B 구간 반복, 배속(0.5 ~ 2.0, 음높이 유지), 이어폰 분리 · 블루투스 끊김 때 일시정지 · 다시 연결 시 이어 재생 설정, 다른 앱 소리와 섞기.
- **이퀄라이저**: 기기 대역 수에 맞춘 슬라이더와 프리셋, 저음 강화, 입체 음향, 잔향(직접 만든 Freeverb 방식), 리미터. 출력 기기(블루투스 · 유선 · 스피커)마다 값을 따로 저장해 자동 적용합니다. [docs/equalizer.md](docs/equalizer.md)
- **영상**: 네이티브 ExoPlayer가 소리와 영상을 한 시계로 재생하고 Dart는 공유 텍스처로 그리기만 합니다. 영상 재생 중 홈으로 나가면 PiP로 뜹니다. 알림 · 포그라운드 서비스에는 영상이 보이지 않습니다.
- 플레이어 화면은 여러 모양(테마) 중에서 고르고, 곡의 커버 색을 배경에 쓸 수 있습니다.

## 8. 보관함 · 재생목록 · 커버

- 곡 · 앨범 · 아티스트 · 장르별 보기, 정렬, 기기에 이미 있는 음악 불러오기(폴더 선택).
- 재생목록: 대표곡, 좋아요, 키워드 검색, 여러 곡 선택해 담기, 카드 요약 색.
- 커버: 직접 고른 이미지 · 웹에서 가져온 이미지(확대 · 위치 조정), 기본 커버는 중립 회색 + 장르별 색. 받는 곡의 기본 커버는 유튜브 썸네일입니다.
- **파일이 원본**: 제목 · 아티스트 · 앨범 · 장르 · 가사 · 커버가 파일 태그에 들어 있어, 앱을 다시 설치해도 태그를 읽어 DB를 복원합니다. 수정은 태그를 먼저 쓰고 DB를 나중에 바꿉니다. Android 저장소 정책상 다시 설치한 앱은 곡마다 쓰기 동의가 필요할 수 있습니다.

## 9. 가사

- 가사 위치: 파일 태그(mp3는 ID3 `LYRICS` 칸(TXXX)과 USLT, opus 등은 태그) → 앱 DB 캐시 순으로 읽습니다.
- **웹 검색으로 가져오기**: 앱 안 웹 화면에서 검색한 뒤 가사를 "담기"로 모아 저장합니다.
- **싱크 맞추기**: 줄마다 시간을 찍어 싱크 가사로 만들고, 도중에 저장하면 찍은 줄까지만 저장합니다. 전체 지연(ms) 보정도 있습니다. 싱크가 없는 가사도 그냥 보여 줍니다.
- **화면 위 가사**: 다른 앱 위에 띄우는 오버레이 (오버레이 권한 필요, 네이티브).
- 가사를 고쳐 저장하기 전에 쓰기 동의를 먼저 받습니다.

## 10. 홈 · 설정 · 보안

- 홈: 많이 들은 곡, 최근 재생, 청취 통계. 재생 기록(들은 시간은 실제 재생된 시간만)은 기기에만 저장됩니다.
- 화면: 다크 · 라이트 · 시스템(기본 다크), 테마 색 프리셋, 곡 분위기 색 옵션. 글자는 Pretendard, 문구는 한국어 · 영어.
- 보안: 앱 잠금(PIN 4 ~ 6자리 + 선택 생체 인증), 알림에 곡 정보 숨기기.
- 저장 · 캐시: 스트리밍 임시 저장 용량, 저장한 음원 · 영상 사용량 확인.
- 알림: 받기 진행 · 결과, 재생 알림, 구독 새 영상.

## 11. 데이터 · 개인정보

- 곡 · 재생 기록 · 재생목록은 모두 기기 안 DB(drift)에 있습니다. 서버로 보내지 않습니다 (서버 모드는 아직 없음).
- 구글 로그인 정보는 기기의 보안 저장소(flutter_secure_storage)에만 저장되고, 읽기 범위는 `youtube.readonly`입니다.
- 저장소에는 음원 파일 · 저작권 있는 곡 주소 · API 키 · 비밀값을 넣지 않습니다.

---

## 빌드해서 실행하기

필요한 것: Flutter (Dart `^3.13.3`), Android SDK.

```bash
flutter pub get
flutter run                          # full 빌드 (기본)
flutter build apk --flavor full      # 배포용 APK
```

배포(CI · 서명 · GitHub Release)는 [docs/release.md](docs/release.md)를 봅니다.

### 빌드 종류 (Android flavor)
| flavor | 내용 |
|---|---|
| `full` (기본) | 기기 안에서 받기까지 하는 로컬 엔진(yt-dlp · ffmpeg)이 APK에 들어갑니다 |
| `lite` | 서버 모드만. 서버가 배포되기 전에는 쓰지 않습니다 |

### 빌드 설정값 (`--dart-define`)
값은 저장소에 넣지 않고 로컬 파일이나 빌드 명령에서만 지정합니다. 예시는 [dart_defines.example.json](dart_defines.example.json), 로컬 값은 `dart_defines.local.json`(git 제외)에 둡니다.

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

| 이름 | 쓰임 |
|---|---|
| `MULO_API_BASE_URL` | 서버 주소 (서버 모드 · `lite` 빌드). 비어 있으면 서버 미연결 |
| `MULO_GOOGLE_SERVER_CLIENT_ID` | 구글 로그인 (내 유튜브 재생목록). 설정법은 [docs/google-login-setup.md](docs/google-login-setup.md) |

### 확인 명령
```bash
flutter analyze
flutter test
flutter gen-l10n        # 문구(ARB) 수정 뒤
dart run build_runner build -d   # DB 스키마 수정 뒤
```

## 구조

클린 아키텍처 + BLoC, 기능별(feature-first) 폴더입니다.

```
lib/
  app/        앱 진입, 라우터(go_router), 탭 틀
  core/       DI(get_it), 디자인 시스템, 로컬 DB(drift), 공통 유틸
  features/<기능>/
    domain/       entities · repositories · usecases (순수 Dart)
    data/         datasources · repositories
    presentation/ bloc · screens · widgets
  l10n/       문구 (ko · en)
android/      Kotlin 네이티브: Media3 재생 서비스 · 이퀄라이저 · 유튜브 해석 · 태그 쓰기 · 알림
docs/         규칙 · 설계 결정 · 작업 기록
```

- **Flutter는 화면만**: 재생 엔진 · 대기열 · 셔플 · 반복 · 영상 · 파일 태그 · 유튜브 주소 해석은 네이티브가 맡고, Dart는 명령을 보내고 결과를 비춥니다 ([docs/native-playback.md](docs/native-playback.md)).
- 의존 방향은 presentation → domain ← data 이고 `test/architecture_test.dart`가 검사합니다.
- 상태: flutter_bloc · 의존성: get_it · 로컬 DB: drift · 설정값: shared_preferences

## 문서

| 문서 | 내용 |
|---|---|
| [CLAUDE.md](CLAUDE.md) | 프로젝트 규칙 |
| [docs/](docs/README.md) | 문서 목차 |
| [docs/git.md](docs/git.md) | 브랜치 · 커밋 · PR 규칙 |
| [docs/design-system.md](docs/design-system.md) | 디자인 시스템 |
| [docs/decisions.md](docs/decisions.md) | 설계 결정 기록 |
| [docs/native-playback.md](docs/native-playback.md) | 네이티브 재생 약속 |
| [docs/equalizer.md](docs/equalizer.md) | 이퀄라이저 |

## 알아 두기

- 서버(Spring Boot REST)는 별도 저장소이며 아직 배포 전입니다. 지금 앱은 서버 없이 로컬 모드로 동작합니다.
- Google Play에는 유튜브 다운로더가 올라갈 수 없어, 배포는 GitHub APK로 합니다.
- 글꼴은 [Pretendard](https://github.com/orioncactus/pretendard) (SIL OFL 1.1)를 씁니다.
