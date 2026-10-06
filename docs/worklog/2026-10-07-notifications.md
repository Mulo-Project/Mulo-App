# 알림 기능 (받기 · 재생 · 설정)

- 날짜: 2026-10-07
- 분류: 앱 · 설정
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/notifications`
- 상세 기능: 알림 곡 정보 숨기기 (#32) + 받기 · 재생 알림

## 한 일
- `features/notifications` 추가 ([D-071](../decisions.md)): 받기 진행 · 완료 · 실패 알림, 재생 알림(조작 · 커버 · 이동 막대), 곡 정보 숨기기 동작, 설정 알림 섹션, 권한 안내.
- 설정 보안 섹션의 숨기기 스위치를 저장되는 실제 설정으로 연결.

## 바꾼 설정
- pubspec: `audio_service ^0.18.19`, `flutter_local_notifications ^19.0.0` 추가.
- AndroidManifest: 알림 · 포그라운드 서비스 권한, audio_service 서비스 · 리시버, flutter_local_notifications 포그라운드 서비스(dataSync).
- `MainActivity`: `AudioServiceFragmentActivity` 상속. Gradle: core library desugaring 켬. 드로어블 `ic_stat_mulo`.
- ARB: 알림 문구 (ko · en).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (알림 동기화 테스트 추가).
- Android 빌드는 이 PC의 Flutter SDK(`engine.stamp` 없음) 문제로 확인하지 못했다. 기기에서 확인 필요.

## 남은 일 · 질문
- 기기 확인: 재생 알림 조작 · 커버 · 숨기기, 받기 중 앱을 뒤로 보냈을 때 이어지는지, Android 13+ 권한 창.
- Notion 작업 기록 · 기술 스택(Flutter) 행 추가.
