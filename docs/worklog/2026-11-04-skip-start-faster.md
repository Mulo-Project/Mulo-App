# 곡 이동 시작 속도 개선 (2026-11-04)

## 원인 분석 (코드 읽기, 실기기 측정 전)
- 곡이 바뀌면 `PlaybackHub.onMediaItemTransition`이 메인 스레드에서 `refreshLayout()`을 부른다.
- 이때 Dart가 보낸 알림 내용은 아직 이전 곡의 것이라 `dartHandlesFavorite()`가 false → `favoriteOn()`이 `FavoriteStore.isFavorite()`로 앱 SQLite(drift)를 **메인 스레드에서 열고 읽었다** (곡 이동마다, Dart의 DB 쓰기와 겹치면 더 느림).
- Dart의 `play`/`seek` 명령도 같은 메인 스레드로 오므로 그 시간만큼 소리 시작이 밀릴 수 있다.

## 변경
- 좋아요 DB 읽기를 전용 단일 스레드로 옮기고, 읽는 동안에는 직전에 읽은 값(없으면 이 곡의 앱 값, 아니면 꺼짐)을 먼저 보여 준 뒤 결과가 다르면 알림 버튼을 다시 맞춘다.
- 알림 좋아요 버튼의 DB 쓰기도 같은 스레드에서 한다.

## 확인 필요
- PC: `dart format`, `flutter analyze`, `flutter test`, Android 빌드 (이 환경은 빌드 불가).
- 기기: `adb logcat -s MuloPlayback`의 `소리까지 NNNms` 전후 비교. 여전히 느리면 그 로그를 보내 주세요 (다음 후보: 코덱 전환 시 AudioTrack 재생성, 다음 곡 미리 준비).
