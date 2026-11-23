# 받기 알림 · 포그라운드 서비스 복원 (네이티브)

- 날짜: 2026-10-11
- 분류: 앱 · 설정
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `feature/download-notification`
- 상세 기능: 알림 (받기 · 백그라운드 받기)

## 한 일
- [D-095](../decisions.md): D-091로 지웠던 받기 알림 · 포그라운드 서비스 · 관련 설정을 되살림. 닫힌 PR(#90)의 네이티브 Kotlin 구현을 현재 develop(재생 알림 네이티브 이전 · 하단 받기 줄 이후)에 맞춰 가져옴.
- Dart: D-091 병합 커밋을 되돌려 `DownloadNotifier` · 동기화 · 설정 · 문구 · 테스트 복원. `LocalDownloadNotifier`는 채널 어댑터.

## 바꾼 설정
- pubspec: 변경 없음 (`flutter_local_notifications`는 쓰지 않음).
- AndroidManifest: `FOREGROUND_SERVICE_DATA_SYNC` 권한, `.DownloadForegroundService`(dataSync) · `.DownloadActionReceiver`(비공개).
- Kotlin 추가: `DownloadNotificationPlugin` · `DownloadNotifications` · `DownloadForegroundService` · `DownloadActionReceiver`. `MainActivity`는 엔진에 플러그인을 붙인다.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite` (결과는 PR에 적음).
- 기기 확인 필요: 받는 중 홈으로 나가도 받기가 이어지고 알림의 미리듣기 / 일시정지 / 중지 / 취소 버튼이 앱을 앞으로 가져오지 않고 동작하는지. 전체 일시정지 때 알림 문구.

## 남은 일 · 질문
- Notion 작업 기록 · 기술 스택 갱신.
