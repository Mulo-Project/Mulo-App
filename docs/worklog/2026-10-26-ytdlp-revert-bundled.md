# Android yt-dlp 업데이트 지우기 (번들 버전으로 복귀)

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `feature/ytdlp-revert-bundled` (기반: `develop`)
- 상세 기능: yt-dlp 업데이트 (설정 > 다운로드 엔진)

## 한 일
- Android full에서 yt-dlp를 업데이트한 뒤 문제가 생기면 APK에 들어 있던 버전으로 되돌리는 설정 엔진 줄의 "삭제"가 업데이트한 yt-dlp를 지워 번들 버전으로 돌아가게 했다 (D-132). 업데이트한 적이 있을 때만 보이고, 확인창을 거친다.
- 네이티브 `YtDlpChannel`(full)에 `revert`: 업데이트가 받은 `yt-dlp` 폴더와 저장된 버전(`dlpVersion` · `dlpVersionName`)을 지우고 `init_ytdlp`로 번들 파일을 다시 푼다. lite에는 없다.
- `YtDlpManager.remove()`가 Android에서 `revert`를 부른다. `EngineStatus.revertible`(지우면 번들로 복귀) · 되돌리는 중 · 실패 문구를 따로 둔다 (`EngineState.reverting`).
- Android의 엔진 상태: 번들 yt-dlp는 늘 쓸 수 있으므로 `installed`를 항상 true로 하고, 업데이트 전에는 "앱에 들어 있는 yt-dlp"로 보인다 (전에는 "yt-dlp가 없어요").

## 바꾼 설정
- 패키지 · Gradle · Manifest 변경 없음. ARB에 `settingsEngineRevert*` · `settingsEngineReverting` · `settingsEngineBundled` 추가.

## 확인
- `flutter analyze` 경고 0, 관련 테스트(엔진 설정 · `AndroidYtDlp`) 통과, `gradlew :app:compileFullDebugKotlin` 컴파일 통과.
- 실제 기기에서 업데이트 → 되돌리기는 직접 확인하지 못했다.

## 남은 일 · 질문
- 번들 yt-dlp의 버전 번호 표시는 하지 않았다 (필요하면 `--version` 실행으로 읽을 수 있음).
