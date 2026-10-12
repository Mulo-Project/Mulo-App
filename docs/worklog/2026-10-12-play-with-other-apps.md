# 다른 앱과 함께 재생 설정

- 날짜: 2026-10-12
- 분류: 앱
- 상태: 진행 중 (PR 확인 대기)
- 브랜치 · 커밋: `feature/play-with-other-apps`

## 한 일
- 설정 '재생 설정' 카드에 '다른 앱과 함께 재생' 스위치 (기본 꺼짐, shared_preferences `player.mixWithOthers`).
- 켜면 ExoPlayer 오디오 포커스 처리를 끈다 (`setAudioAttributes(..., handleAudioFocus = !mix)`). 다른 앱이 소리를 내도 멈추지 않고 겹쳐 들린다.
- 앱 시작 때 저장값을 재생 서비스에 반영, 스위치를 바꾸면 즉시 반영. Android만 해당 (그 밖의 OS는 저장만).

## 바꾼 설정
- `PlaybackChannel`에 `setMixWithOthers` 추가 (docs/native-playback.md에 적음). 패키지 · 권한 변화 없음.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과. 실기기에서 다른 앱과 겹침은 직접 확인 필요.

## 남은 일 · 질문
- 볼륨을 낮추며 같이 듣는 방식(ducking)은 넣지 않음.
- 재생 화면에서 영상 함께 보기는 별도 작업으로 나중에.
