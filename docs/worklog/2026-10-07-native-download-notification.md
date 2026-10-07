# 받기 알림 · 포그라운드 서비스 네이티브 이전

- 날짜: 2026-10-07
- 분류: 앱 · 설정
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `feature/native-download-notification`
- 상세 기능: 알림 (받기 · 백그라운드 받기)

## 한 일
- 받기 알림 · 포그라운드 서비스 · 버튼 수신을 Kotlin으로 옮김 ([D-090](../decisions.md)). `LocalDownloadNotifier`는 채널 어댑터로 교체.
- MainActivity의 앱 앞으로 가져오기 우회(`sendBackIfDownloadAction`) 제거, `flutter_local_notifications` 의존 제거.

## 바꾼 설정
- pubspec: `flutter_local_notifications` 제거.
- AndroidManifest: 플러그인 서비스 대신 `.DownloadForegroundService`(dataSync) · `.DownloadActionReceiver`(비공개).
- Kotlin 추가: `DownloadNotificationPlugin` · `DownloadNotifications` · `DownloadForegroundService` · `DownloadActionReceiver`. `MainActivity`는 엔진에 플러그인을 붙인다.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor full` 성공.
- 기기 확인 필요: 받는 중 홈으로 나가 알림의 미리듣기 / 일시정지 / 중지 / 취소 버튼이 앱을 앞으로 가져오지 않고 동작하는지.

## 남은 일 · 질문
- Notion 작업 기록 · 기술 스택(Flutter에서 flutter_local_notifications 제거) 갱신.
