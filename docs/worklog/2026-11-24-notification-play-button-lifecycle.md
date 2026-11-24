# 알림 재생 버튼이 시간이 지나면 먹지 않는 문제 고치기

- 날짜: 2026-11-24
- 분류: 앱
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `fix/notification-play-button-service-lifecycle` (기반: `develop`)
- 상세 기능: 공통 작업 (재생 알림 · 포그라운드 서비스)

## 한 일
- 원인과 고침은 [D-172](../decisions.md). `MuloPlaybackService.onDestroy`에서 세션을 서비스에서 떼고, 버튼을 받고도 끝내는 경로에서 포그라운드 약속(`startForeground`)을 지킨다.

## 바꾼 설정
- 없음 (Manifest · Gradle 변경 없음).

## 확인
- 이 작업은 빌드 환경 없이 했다: `flutter analyze` · `gradlew :app:compileLiteDebugKotlin`을 PC에서 돌려 확인해야 한다.
- 기기: 재생 → 일시정지 → 앱을 백그라운드에 10분 이상 → 알림 재생 버튼, 이어서 재생 중 일시정지 · 재생 반복.

## 남은 일 · 질문
- 그래도 먹지 않으면 `adb shell run-as com.mulo.app cat shared_prefs/mulo_playback.xml`의 `stopLog` 한 번 확인.
