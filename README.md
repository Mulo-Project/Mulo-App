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

## 주요 기능

**검색 · 받기**
- 유튜브 검색, 영상 · 채널 · 재생목록 상세 보기, 받기 전 **미리 듣기**(다운로드 없이 스트리밍)
- 음원(mp3 · opus) 또는 영상(mp4 · webm)으로 저장, 이어받기 · 받기 대기열 · 이미 받은 곡 건너뛰기
- 받기 팝업에서 제목 · 아티스트 · 장르 · 커버 · 재생목록 지정, 받기 진행 · 결과 알림
- 구글 로그인으로 내 유튜브 재생목록 · 구독 채널 불러오기, 재생목록 가져오기
- 네이티브 YouTube 해석기를 먼저 쓰고, 안 되면 yt-dlp로 대신합니다 (full 빌드)

**보관함 · 재생목록**
- 곡 · 앨범 · 아티스트 · 장르별 보기와 정렬, 기기에 있는 음악 불러오기
- 재생목록, 좋아요, 곡 · 재생목록 커버 직접 지정(웹 이미지 가져오기 · 확대 · 위치 조정)
- 곡 정보(제목 · 아티스트 · 앨범 · 장르 · 가사 · 커버)는 **파일 태그가 원본**이라 파일만 있어도 복원됩니다

**재생**
- 앱을 닫아도 계속 재생되는 네이티브 재생 서비스, 알림 · 잠금화면 · 블루투스 / 이어폰 버튼
- 셔플 · 반복 · 대기열 편집, A-B 구간 반복, 재생 속도 조절
- 이퀄라이저(대역 · 저음 · 입체 음향 · 잔향 · 리미터)와 출력 기기별 설정
- 영상 재생(음악과 같은 시계), 홈으로 나가면 작은 창(PiP)
- 플레이어 화면 테마 여러 종, 곡 정보 숨기기

**가사**
- 파일 안 가사 표시, 웹에서 검색해 가져오기, 싱크 맞추기, 화면 위에 띄우는 가사

**홈 · 설정**
- 홈 요약과 청취 통계(재생 기록은 기기에만 저장)
- 다크 · 라이트 · 시스템 화면 모드, 테마 색 프리셋, 곡 분위기 색
- 앱 잠금(PIN 4~6자리 + 생체 인증)

## 빌드해서 실행하기

필요한 것: Flutter (Dart `^3.13.3`), Android SDK.

```bash
flutter pub get
flutter run                          # full 빌드 (기본)
flutter build apk --flavor full      # 배포용 APK
```

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
