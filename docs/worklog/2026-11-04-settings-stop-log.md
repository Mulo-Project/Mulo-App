# 설정에 재생 중단 기록 보이기

- 날짜: 2026-11-04
- 분류: 앱
- 상태: 진행 중 (PC 확인 · 기기 확인 대기)
- 브랜치 · 커밋: `feat/settings-stop-log` (기반: `develop`)
- 상세 기능: 공통 작업 (재생 끊김 진단, [2026-10-28](2026-10-28-media-button-resume.md)에 이어)

## 한 일
- 네이티브: `PlaybackStore.readStopLog` · `clearStopLog`, `PlaybackChannel`에 `stopLog` · `clearStopLog` 메서드.
- Dart: `StopLogRepository` · `GetStopLog` · `ClearStopLog` · `StopLogCubit`, 바텀 시트 `showStopLogSheet`, 설정 > 정보에 "재생 중단 기록" 줄(Android만). 문구는 ARB에 추가하고 생성 파일(`app_localizations*.dart`)은 손으로 같게 맞췄다.
- 테스트: `stop_log_cubit_test.dart`.

## 바꾼 설정
- 없음 (Manifest · pubspec · Gradle 변경 없음).

## 확인
- 클라우드 스레드라 빌드 · 분석 · 테스트를 못 돌렸다. PC에서 `dart format .`, `flutter gen-l10n`(생성 파일 diff 없는지), `flutter analyze`, `flutter test`가 필요하다.
- 기기: 설정 > 정보 > 재생 중단 기록 시트가 열리고, 기록이 보이고, 지우면 비는지.
