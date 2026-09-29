# 프로젝트 규칙 (Music-Download-Play-App)

유튜브 등에서 음원을 받아 저장하고 같은 앱에서 재생하는 한국어 UI 음악 앱.
이 저장소는 **Flutter 앱**(Android · Windows · macOS · Linux)만 담는다. Spring Boot REST 서버는 별도 저장소 (D-008).
기능 명세 원본은 Notion [음악 다운로더 & 플레이어 기능명세서](https://app.notion.com/p/3eac450c43a581d18ef4f5a4b93bb3bb). 프로젝트 문서는 [docs/](docs/README.md).

## 진행 방식
- 명세의 **단계**(MVP → v2) 순서로 진행한다. 첫 대상: 서버 + Android lite.
- 작업 단위는 Notion **상세 기능** 하나 (없으면 디자인 · 설정 같은 공통 작업 하나).
- 규칙 · 절차는 스스로 정해 `docs/`에 기록하고 따른다. 이미 정한 것은 다시 묻지 않는다.
- 명세가 모호하거나 Notion과 코드가 다르면 추측하지 말고 사용자에게 묻는다.
- 코드 · 설정(pubspec, Gradle, Manifest 등)을 바꾸면 무엇을 바꿨는지 보고에 적는다.

## 기록
- 작업 하나를 마치면 `docs/worklog/`에 파일 하나를 남긴다 ([형식](docs/worklog/README.md)).
- 설계 결정은 [docs/decisions.md](docs/decisions.md)에 번호를 매겨 남긴다.
- Notion [작업 현황](https://app.notion.com/p/3eac450c43a581dca8caf650a6d030a8)의 **작업 기록 DB**에 작업 하나 = 한 행으로 옮긴다.
  작업 · 날짜 · 분류 · 상태 · 요약 · 커밋 · 문서(worklog 경로) · 상세 기능(관계)을 채운다. 상세 원본은 항상 `docs/`.
  갱신 시점: 작업 시작(진행 중) · 완료 · 보류, 중요한 결정.
- 새 패키지 · 에셋 · 네이티브 기능을 쓰면 Notion **기술 스택**의 해당 DB(Backend · Flutter · Native)에 행을 추가한다.

## Git (상세: [docs/git.md](docs/git.md))
- `main` · `develop`에 직접 커밋하지 않는다. 작업 브랜치는 `develop`에서 딴다: `feature/` · `ui/` · `fix/` · `chore/` · `docs/`.
- 커밋: `<type>(<scope>): <한국어 요약>`. 예: `feat(player): 미니 플레이어 재생 상태 연결`
- 작업 브랜치 커밋 · push는 자유롭게. **`develop` · `main`으로 합칠 때만 사용자 승인을 받는다.**

## 아키텍처
- Flutter: MVVM + Riverpod, feature-first 폴더, 계층은 presentation / domain / data.
- 다운로드는 `DownloaderEngine` 인터페이스 → `ServerEngine`(서버 모드) / `LocalEngine`(로컬 모드).
- Android 빌드는 flavor `lite`(서버 모드만) / `full`(두 모드). 데스크톱은 빌드 하나에 설정으로 모드 선택.
- 앱 로컬 DB는 drift, 설정값은 shared_preferences, 재생은 just_audio + audio_service. (Notion 기술 스택 기준)
- 테마는 디자인 시스템(`lib/core/design/`)의 테마 소스로만 바꾼다 ([design-system.md](docs/design-system.md)).

## 폴더 구조
```
lib/
  app/            # 앱 진입, 라우터(go_router), 탭 틀
  core/
    design/       # 디자인 시스템: 토큰, 테마 소스, 공통 컴포넌트(유리)
    l10n/         # context.l10n
    sample/       # UI 퍼블리싱용 가짜 데이터 (기능 연결 후 삭제)
  features/<기능>/
    presentation/ # 화면, ViewModel
    domain/       # 모델, 리포지토리 인터페이스
    data/         # 리포지토리 구현
  l10n/           # ARB (ko 템플릿, en) + 생성 코드
assets/fonts/     # Pretendard
docs/             # 규칙 · 결정 · 작업 기록
```

## 코드 스타일
- `flutter analyze` 경고 0, `dart format` 적용, `flutter test` 통과 후 커밋.
- 색 · 그라데이션은 토큰(`context.palette`, `context.tokens`)에서만 읽는다. 화면에 `Color(0x…)` · `Colors.xxx` 금지.
- 간격 · 반경 · 시간은 `AppSpacing` · `AppRadii` · `AppMotion`, 글자는 `textTheme`(Pretendard), 큰 숫자는 `StatNumber`.
- 면은 유리(`GlassSurface` · `GlassCard`), 공통 모양은 `lib/core/design/components/`에 만들고 [design-system.md](docs/design-system.md)에 적는다. Material 버튼 · AppBar · ListTile · Switch · Chip · Slider를 화면에서 직접 쓰지 않는다.
- 화면 문구는 ARB(`lib/l10n/`, 한국어 · 영어)에서 `context.l10n`으로 가져온다.
- 생성 코드(`*.g.dart`, `*.freezed.dart`)는 직접 고치지 않는다.
- 저장소에 음원 파일이나 저작권 있는 곡 URL을 넣지 않는다 (README · 테스트 포함). API 키 · 비밀값도 넣지 않는다.

## 자주 쓰는 명령
- 실행: `flutter run`
- 확인: `flutter analyze`, `flutter test`, `flutter build apk --debug`
- 문구 재생성: `flutter gen-l10n` (ARB 수정 후)
- 스크린샷: `flutter test --run-skipped -t screenshot test/screenshots` → `build/screenshots/`
