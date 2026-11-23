# 시간 초과 전용 안내

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `fix/search-timeout-message` (기반: `develop`)
- 상세 기능: 검색 · 재생목록 가져오기 (공통 안내)

## 한 일
- 시간 초과를 연결 실패(`network`)에서 떼어 `EngineFailure.timeout` · `AccountFailure.timeout`으로 나눴다 (D-126).
- `EmptyState.timeout`(`EmptyKind.timeout`) 추가: "응답이 너무 오래 걸려요" + 다시 시도. ARB `stateTimeout*`(ko · en).
- 적용: 검색 화면, 재생목록 가져오기(링크 · 내 계정), 내 구독 채널, 미리 듣기 스낵바, 다운로드 큐 실패 사유.
- 시간 초과 지점: 서버 엔진 · 로컬 yt-dlp · 재생목록 대체 경로(explode) · 미리 듣기 · 구글 계정 API / 로그인.

- 안드로이드 `full` yt-dlp: `AndroidYtDlp.run`에 60초 제한 + 네이티브 `cancel` 메서드(`YtDlpChannel.kt`, `destroyProcessById`) 추가.

## 바꾼 설정
- 패키지 · Gradle · Manifest 변경 없음. 네이티브 채널 `music_app/ytdlp`에 `cancel` 메서드와 `run`의 `id` 인자 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 전체 통과. `test/core/empty_state_test.dart` 추가, 로컬 yt-dlp 시간 초과 테스트는 `timeout` 기대로 바꿨다.
- `compileFullDebugKotlin` 통과, 시간 초과 시 `cancel` 호출 단위 테스트. 실제 기기에서 yt-dlp가 멈추는 상황과 `destroyProcessById`가 프로세스를 끊는지는 확인하지 못했다.
- 실제 기기에서 시간 초과를 일으켜 화면을 보는 것은 이 PC에서 하지 못했다.

## 남은 일 · 질문
- (없음)
