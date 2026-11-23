# 재생 속도 옵션

- 날짜: 2026-10-15
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/player-playback-speed`
- 상세 기능: 재생 옵션 (공통 작업)

## 한 일
- 재생 화면 ⋮ 메뉴에 "재생 속도 · 보통" 줄을 더함 (카드 없이 기존 팝업 메뉴). 누르면 0.5 · 0.75 · 보통 · 1.25 · 1.5 · 2배속 목록이 뜨고, 고르면 바로 소리에 반영 · 저장.
- Flutter: `PlaybackSpeed`(고를 수 있는 값) · `PlaybackSpeedRepository`(shared_preferences `player.playbackSpeed`) · Load/Save 유스케이스 · `PlaybackSpeedCubit`(앱 시작 때 바로 불러와 엔진에 반영). 곡이 바뀌어도 같은 속도.
- Android 네이티브: `setSpeed` 메서드 추가 → `PlaybackHub.setSpeed`가 `ExoPlayer.setPlaybackSpeed`(음높이 유지)로 걸고 `PlaybackStore`에도 저장해 앱 없이 프로세스가 새로 떠도 같은 속도. `SessionPlayer`가 배속을 세션 상태(`PlaybackParameters`)에 실어 알림 · 잠금화면 진행 막대가 실제 속도로 흐른다 (미리 듣기는 1배).
- 데스크톱: `AudioEngineSource.setSpeed` → just_audio `setSpeed`.

## 바꾼 설정
- 없음 (패키지 · Gradle · Manifest 변경 없음). 문구: `playerSpeedTitle` · `playerSpeedValue` · `playerSpeedNormal` (ko · en).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과.
- 폰에서 확인 필요: 배속에서 음높이 유지 · 알림 진행 막대 · 앱을 밀어도 속도 유지.
