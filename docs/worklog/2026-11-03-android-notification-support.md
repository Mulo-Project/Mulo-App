# Android 네이티브 알림 도우미 공통화 (리팩터링 1단계)

- 날짜: 2026-11-03
- 분류: 앱 (Android 네이티브)
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `refactor/android-notification-support`
- 상세 기능: 공통 작업 (코드 정리, 동작 변경 없음)

## 한 일
- `DownloadNotifications`와 `NewVideoNotifications`에 똑같이 있던 `manager` · `builder` · `smallIcon` · `addAction` 과 인텐트 플래그를 `NotificationSupport.kt` 한 곳으로 모음. 각 파일은 짧은 위임 함수만 남김.
- `LyricsOverlay`에서 같은 `getSharedPreferences(PREFS, ...)` 호출 5곳을 `prefs()` 하나로 줄임.
- 알림 내용 · 채널 · 요청 코드 · 플래그 값은 그대로다.

## 바꾼 설정
- 없음 (패키지 · Manifest 변경 없음).

## 확인
- 클라우드 환경이라 Android SDK가 없어 `flutter analyze` · 빌드는 돌리지 못했다. 코드를 줄 단위로 대조해 시그니처 · import만 확인.
- **실기기 확인 필요**: 받기 진행 알림(버튼 · 진행률), 받기 완료 알림, 구독 새 영상 알림(바로 받기 · 취소), 가사 오버레이 위치 저장.

## 남은 일 · 질문
- 다음 단계 후보: `MediaStoreChannel` · `PreviewChannel` 등 채널 클래스의 공통 틀 정리, `LyricsOverlay.kt`(850줄) · `PlaybackHub.kt`(870줄) 분리. 실기기 확인이 가능할 때 진행.

## 추가 (같은 브랜치, 2026-11-03)
- 알림 좋아요를 앱 없이도 네이티브에서 처리 → `2026-11-03-notification-favorite-native.md` 참고 (D-136).
- `DownloadForegroundService.onTimeout`: Android 15 dataSync 시간 제한 대응. 알림 떼어 내고 서비스 정지, `stopLog` 기록.
- `DownloadActionReceiver`: 받아 줄 엔진이 없으면 낡은 받기 알림을 치운다 (`DownloadNotificationPlugin.dispatch`가 처리 여부를 돌려줌). D-137.
- 실기기 확인: 받기를 6시간 넘게 돌렸을 때 크래시 없이 알림만 남는지(재현이 어려워 코드 대조만 함), 앱을 강제 종료한 뒤 남은 받기 알림 버튼을 눌렀을 때 알림이 사라지는지.
- 채널 클래스 공통 틀 `NativeChannel.kt`: `MethodChannel` 생성 · `dispose` 반복을 9개 채널(main 7 + yt-dlp · 변환, full · lite 각각)에서 상속으로 정리 (D-138). 동작 변경 없음. 실기기 확인: 앱 시작 직후 각 기능(보관함 조회, 가사, 이퀄라이저, 미리 듣기, 구독, 출력 기기 알림)이 평소처럼 동작하는지.
- `PlaybackHub.kt`(871 → 795줄) · `LyricsOverlay.kt`(852 → 821줄)에서 상태 없는 계산을 파일로 분리 (D-139): `PlaybackButtons` · `QueueShuffle` · `QueueMapping` · `LyricsTimeline`. 동작 변경 없음.
- 실기기 확인: 알림 셔플 켜기/끄기(앱을 밀어 끈 상태 포함), 셔플 중 한 바퀴 돈 뒤 다시 섞이는지, 반복 모드 유지, 대기열 곡 정보, 가사 줄 따라가기와 줄 전환 타이밍, 가사 창 숨기기/끄기 버튼 색.
