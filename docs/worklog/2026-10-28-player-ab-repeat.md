# 구간(A-B) 반복 재생

- 날짜: 2026-10-28
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/player-ab-repeat`
- 상세 기능: 재생 옵션 (공통 작업)

## 한 일
- 플레이어 화면 하단 보조 줄(셔플 · 반복 옆)에 `A-B` 버튼을 더함. 누를 때마다 지금 위치를 시작 → 끝으로 정하고(끝이 시작 뒤 1초 안이면 무시) 그 구간만 반복, 한 번 더 누르면 해제. 버튼 옆 글자로 `A 01:05` / `A-B 01:05-02:10`을 보여 주고, 진행 막대에도 구간을 강조선으로 그린다. 보조 줄 안이라 조작부 높이(화면 1/3 이하)는 그대로.
- 반복 판정은 네이티브: `setLoop({startMs, endMs})` 메서드 → `PlaybackHub`의 위치 타이머가 구간 반복 중에는 40ms마다 위치를 보고 끝 지점에 닿으면 `seekTo(start)`. 앱이 꺼져 있어도 이어진다. 곡이 바뀌거나 대기열 끝에 닿으면 네이티브가 풀고, 앱(`NowPlayingCubit`)도 곡이 바뀌면 상태를 지운다.
- Flutter: `NowPlayingState.loopStart/loopEnd/looping`, `cycleLoop()` · `clearLoop()`, `AudioPlayerRepository.setLoop`, `SetAudioLoop` 유스케이스, 문구(ARB 한국어 · 영어).

## 바꾼 설정
- 없음 (패키지 · Manifest 변경 없음). Android 네이티브: `PlaybackHub.kt` · `PlaybackChannel.kt`. 약속은 `docs/native-playback.md`에 `setLoop` 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과(구간 지정 · 해제 · 곡 변경 시 해제 테스트 추가), `flutter build apk --debug --flavor full` 성공.
- 실제 기기에서 반복 지점의 정확도(약 40ms 이내 오차)는 확인하지 못했다.

## 남은 일 · 질문
- 데스크톱(Windows 등)은 엔진이 달라 아직 없다 (명령이 무시됨).
- 구간 값은 저장하지 않는다 (곡을 바꾸거나 앱을 다시 켜면 풀림).
