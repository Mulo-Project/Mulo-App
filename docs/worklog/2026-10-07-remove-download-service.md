# 받기 알림 · 포그라운드 서비스 제거

- 날짜: 2026-10-07
- 분류: 앱 · 설정
- 상태: 진행 중 (확인 대기)
- 브랜치 · 커밋: `chore/remove-download-service`
- 상세 기능: 알림 (받기 · 백그라운드 받기)

## 한 일
- [D-091](../decisions.md): 받기 포그라운드 서비스 · 진행 알림 · 알림 버튼 · 백그라운드 받기 / 받기 진행 알림 설정 제거. 결과 알림 · 설정도 같이 제거. 재생 알림만 유지.
- `DownloadNotifier` · `LocalDownloadNotifier` · `NoDownloadNotifier` 삭제, `NotificationSyncCubit` · `NotificationBridge`는 재생 알림만 다룸.
- 불필요해진 ARB 문구 정리, 알림 동기화 테스트에서 진행 알림 테스트 삭제.

## 바꾼 설정
- pubspec: `flutter_local_notifications` 제거 (재생 알림은 `audio_service`).
- 설정 `downloadResult`(받기 결과 알림)도 제거.
- AndroidManifest: 받기 서비스 선언과 `FOREGROUND_SERVICE_DATA_SYNC` 권한 제거.
- `MainActivity`: 알림 버튼용 `moveTaskToBack` 우회 제거.
- 저장된 설정 키(`notification.downloadProgress` · `notification.backgroundDownload`)는 더 읽지 않는다 (남아 있어도 무해).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite` 성공.
- 기기 확인 필요: 받기 중 알림이 안 뜨는지, 받기가 끝나도 알림이 안 뜨는지, 설정 > 알림에서 백그라운드 받기 · 받기 진행 알림 항목이 없어졌는지.

## 남은 일 · 질문
- Notion 작업 기록 갱신.
