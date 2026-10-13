# 포그라운드 서비스 고치기 (미리 듣기 · 받기)

- 날짜: 2026-10-14
- 분류: 앱
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `fix/foreground-service-preview-download`
- 상세 기능: 공통 작업 (알림 · 포그라운드 서비스)

## 한 일
- 원인: (1) 최근 작업에서 앱을 밀면 Flutter 엔진이 화면과 함께 죽어 Dart가 하던 받기가 멈췄다 (서비스 알림만 남음). (2) 재생 알림을 닫은 상태에서는 미리 듣기가 알림 세션에 올라가지 못해 포그라운드가 되지 않았다.
- `MuloEngine.kt` 추가: 엔진 · 채널을 화면과 따로 쥐고, 받기 서비스/미리 듣기가 있는 동안 살려 둔다. `MainActivity`는 이 엔진을 빌려 쓴다.
- `PlaybackHub.setSession`: 닫힌 상태에서도 미리 듣기 동안은 세션을 되살려 서비스에 올린다.
- `DownloadForegroundService.wanted`로 서비스가 붙들기로 한 상태를 표시한다.

## 바꾼 설정
- 없음 (Kotlin만 변경, 매니페스트 · pubspec 그대로).

## 확인
- `flutter analyze` 0, `flutter test` 통과, `flutter build apk --debug --flavor lite` 성공.
- 실기기 확인 필요: 받는 중 최근 작업에서 밀기 → 계속 받는지, 알림을 닫은 뒤 미리 듣기 → 앱을 뒤로 보내도 이어지는지.

## 추가 수정 (2026-10-14, PR 107에 합침)
- 최근 작업에서 앱을 밀면 `MuloPlaybackService.onTaskRemoved`가 메인 플레이어(`exo`)가 멈춰 있다는 이유로 세션을 정리해, 미리 듣기 알림이 함께 사라졌다 (미리 듣기는 Dart 플레이어가 소리를 낸다).
- 미리 듣기가 소리를 내는 동안은 정리하지 않고, 멈춘 미리 듣기는 알림만 치운다 (`PlaybackHub.isPreviewPlaying`).
- 실기기 확인 필요: 미리 듣기 중 최근 작업에서 앱 밀기 → 알림 · 소리 유지.
