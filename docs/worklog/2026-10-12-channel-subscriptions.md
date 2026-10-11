# 채널 구독 · 새 영상 골라 받기

- 날짜: 2026-10-12
- 분류: 앱
- 상태: 진행 중 (PR 확인 대기)
- 브랜치 · 커밋: `feature/channel-subscriptions`
- 상세 기능: (공통 작업 — 명세에 없는 추가 기능)

## 한 일
- [D-100](../decisions.md): 채널 구독 → 새 영상 확인 → 목록에서 골라 받기. 자동 받기는 없다.
- `features/subscriptions`(domain · data · presentation · di) 추가: 구독 저장(prefs JSON), 채널 RSS 읽기, 새 영상 확인, 구독 / 새 영상 cubit.
- 화면: 영상 상세 채널 줄의 구독 버튼, 설정 › 구독 묶음, 구독 채널 목록(켜고 끄기 · 음악만 · 해제), 새 영상 목록(채널별 묶음 · 선택 · 일괄 받기), 앱 실행 시 새 영상 안내.
- Android: `SubscriptionChannel`(`music_app/subscriptions`) · `NewVideoWorker`(WorkManager 주기 확인) · `NewVideoNotifications`(알림, 누르면 새 영상 목록).

## 바꾼 설정
- Gradle: `androidx.work:work-runtime-ktx:2.10.1` 추가. pubspec · Manifest 변경 없음(INTERNET · POST_NOTIFICATIONS는 이미 있음).
- ARB: 구독 · 새 영상 · 설정 · 알림 문구 추가(ko · en).
- 테스트: 설정 화면 높이를 쓰는 `widget_test`의 화면 높이를 7000 → 8000으로.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite` 성공.
- 기기에서 WorkManager 알림 · 알림 누름 이동은 아직 확인하지 않았다.

## 남은 일 · 질문
- 기기 확인: 설정에서 백그라운드 확인을 켜고 1시간 주기 알림이 오는지, 알림을 눌렀을 때 새 영상 목록이 열리는지.
- full 빌드 컴파일은 확인하지 않았다(공통 소스만 추가).
