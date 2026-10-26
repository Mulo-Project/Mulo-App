# 구독 채널 가져오기 500개 제한 해제

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `fix/subscription-import-pagination`
- 상세 기능: 구독 채널 가져오기

## 한 일
- YouTube `subscriptions.list`를 `nextPageToken`이 없을 때까지 끝까지 읽는다 (예전: 10쪽 · 500개에서 멈춤). 안전 상한 400쪽(2만 개), 같은 토큰이 반복되면 중단.
- 불러오는 동안 "구독 채널 N개 불러오는 중…"을 보인다 (`onProgress` → `MySubscriptionsState.loaded`).
- 선택 화면 목록을 `ListView.builder`로 바꿔 긴 목록에서도 보이는 행만 만든다.

## 바꾼 설정
- 없음 (ARB 문구 `channelImportLoading` 추가).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, 페이지 따라가기 테스트(1234개 · 25쪽) 추가.

## 남은 일 · 질문
- 실제 계정(500개 초과)으로 기기 확인은 하지 못함.
