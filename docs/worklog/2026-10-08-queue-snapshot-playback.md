# 재생 대기열을 네이티브에 넘겨 앱이 꺼져도 다음 곡으로 이어가기

- 날짜: 2026-10-08
- 분류: 앱
- 상태: 진행 중 (PR 확인 대기)
- 브랜치 · 커밋: `feature/queue-snapshot-playback`
- 상세 기능: 알림 (재생 알림)

## 한 일
- [D-094](../decisions.md), [native-playback.md](../native-playback.md): 대기열 스냅샷(`setQueue`)을 ExoPlayer 재생목록으로. 곡 넘김 · 반복 · 알림 이전/다음을 네이티브가 처리하고, 앱을 다시 켜면 `getState`로 대기열을 복원한다. 알림을 누르면 현재 곡의 플레이어 화면(`/player`)으로 간다.
- Dart: `AudioPlayerRepository`가 `load`/`watchCompleted` 대신 `setQueue` · `skipTo` · `restore` · 곡 넘김(`track`) · `ended` · `openPlayer`. `NowPlayingCubit`은 곡이 끝나도 다음 곡을 정하지 않고 엔진을 따라간다 (셔플 한 바퀴 다시 섞기는 Dart). `JustAudioPlayerRepository`가 같은 약속으로 곡을 넘긴다 (`AudioEngineSource`는 인터페이스 + `JustAudioEngineSource`로 나눔).
- Kotlin: `PlaybackHub.setQueue/skipTo/getState`, `SessionPlayer`가 대기열을 직접 비춤(곡이 넘어가면 대기열에 실린 정보로 표시), `MainActivity`가 알림 탭 Intent 처리, `PlaybackHub.reset` 제거.

## 바꾼 설정
- 새 패키지 · Gradle 변경 없음. AndroidManifest 변경 없음 (알림 탭은 `MainActivity` 명시적 PendingIntent).
- 채널 약속 변경: `load` 삭제, `setQueue` · `skipTo` · `getState` · `takeOpenPlayerRequest` 추가; 이벤트 `completed` → `ended`, `track` · `openPlayer` 추가; `setSession`에 `trackId` · `hideSongInfo` 등 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite`. 실제 기기 확인(앱 끄고 다음 곡 · 알림 탭 이동 · 재시작 복원)은 필요.

## 남은 일 · 질문
- 앱이 꺼진 사이 알림의 좋아요 별은 숨긴다 (기본값). 프로세스가 죽은 뒤 복원은 하지 않는다.
- 앱이 꺼진 사이 넘어간 곡의 알림 커버: 곡별 커버 주소를 `setQueueArt`로 미리 싣는다 (웹 커버는 지금 곡 앞 3곡 · 뒤 20곡만 CachedWebImage 사본(file 주소)으로, 나머지는 주소 그대로).
- 알림 탭으로 새로 켤 때 덮개로 첫 화면을 가림.
- Windows C++는 같은 약속으로 나중에 구현.
