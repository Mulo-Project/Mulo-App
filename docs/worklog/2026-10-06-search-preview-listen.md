# 검색 결과 미리 듣기

- 날짜: 2026-10-06
- 분류: 앱
- 상태: 완료 (PR 대기, 기기 실행 확인 필요)
- 브랜치 · 커밋: `feature/search-preview-listen` (`develop`에서 분기)
- 상세 기능: 공통 작업 (검색 · 상세 보기 보강, 요청: "미리 듣기 기능")

## 한 일
- 엔진: `DownloaderEngine.resolveAudioStream(url)` 추가 (`AudioStream` = 주소 + 요청 헤더). `LocalEngine`은 yt-dlp로 오디오 형식 하나(m4a 우선)의 주소를 읽고, `RoutingDownloaderEngine` · `CachedDownloaderEngine`이 그대로 넘기고(15분 기억), `ServerEngine`은 `unavailable`.
- 재생: 미리 듣기 전용 `PreviewPlayer` / `JustAudioPreviewPlayer`(별도 just_audio 플레이어). 유스케이스 `ResolveAudioStream` · `PlayPreview` · `StopPreview` · `WatchPreviewCompleted`.
- 상태: `PreviewCubit`(앱 전체 하나). 시작 · 멈춤 · 준비 중 취소 · 다른 곡으로 바꾸기 · 끝 처리.
- 화면: 상세 화면 썸네일 아래 "미리 듣기" 버튼, 검색 줄 오른쪽에 면 없는 작은 `RowIconButton` 미리 듣기 토글(받기 버튼도 같은 모양, 줄마다 유리 버튼을 두면 스크롤이 끊겨서), 길게 누르기 메뉴 "미리 듣기 / 미리 듣기 멈추기".
- 멈춤 규칙: 상세 나가기, 탭 이동, 영상 · 채널 열기, 앱 안 영상 재생 시작, 메인 재생 시작, 다른 곡 미리 듣기. 미리 듣기가 시작되면 메인 재생은 일시정지 (섞지 않음). 결정은 D-061.
- 문구(ko · en) 5개 추가, `flutter gen-l10n`으로 생성 파일 갱신.

## 바꾼 코드 · 설정
- 새 패키지 · Gradle · Manifest 변경 없음 (기존 just_audio · yt-dlp 사용).
- `lib/app/app.dart`: `PreviewCubit` provider. `lib/app/app_shell.dart`: 탭 이동 · 메인 재생 시작 때 미리 듣기 멈춤.
- 테스트 도우미 `test/helpers/fakes.dart`: `FakePreviewPlayer`, `FakeDownloaderEngine.resolveAudioStream`.

## 확인
- `flutter analyze` 0, `flutter test` 전체 통과 (`test/features/search/preview_test.dart` 15개 추가: 엔진 4 · 상태 5 · 화면 6).
- 기기(Android full · 데스크톱)에서 실제로 소리가 나는지는 이 환경에서 돌려 보지 못했다. 테스트는 가짜 플레이어를 쓴다.

## 남은 일 · 질문
- Android lite(서버 모드)는 서버에 스트림 조회 API가 없어 미리 듣기가 안 된다. 서버 쪽에 API를 둘지 결정 필요.
- 미리 듣기 구간 제한(예: 30초)이 필요하면 `PreviewCubit`에서 타이머로 더하면 된다.
