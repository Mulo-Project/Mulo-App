# 구독 화면 임시 확인 영역 삭제

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `chore/remove-subscription-test-area`
- 상세 기능: 공통 (구독 채널)

## 한 일
- 구독 채널 화면 아래 디버그용 "임시 · 모양 확인용" 영역 삭제: "새 영상 알림 띄우기" · "새 영상 화면 미리 보기".
- 관련 코드 삭제: `showTestNotification` (cubit · 유스케이스 · 저장소 · MethodChannel `showTest` · Kotlin), `NewVideosCubit.showSample`과 `sample` 상태 · `isSample`, ARB 문구 3개, 해당 테스트.

## 바꾼 설정
- 없음 (Kotlin `SubscriptionChannel.kt`에서 `showTest` 분기 삭제).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과.

## 남은 일 · 질문
- 실제 새 영상 알림과 앱 실행 시 새 영상 안내 배너는 그대로 둠 (임시 확인용이 아니라 실제 기능).
