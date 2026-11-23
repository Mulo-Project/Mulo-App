# 재생 알림 기본 커버 · 좋아요 버튼

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `feature/media-notification-cover-actions`
- 상세 기능: 재생 알림 (#74 후속)

## 한 일
- 커버 없는 곡도 알림에 앱 기본 커버를 그려 보인다 (`AudioServiceMediaSession._defaultCover`).
- 알림 펼침 버튼: 이전 · 재생 · 다음 · 좋아요(하트) · 닫기. 좋아요는 `MediaCommandType.favorite` → `NotificationBridge` → `PlaylistsCubit.toggleFavorite`.
- 즐겨찾기 상태가 바뀌면 알림 하트 모양을 갱신한다 (`MediaSessionInfo.favorite`).

## 바꾼 설정
- Android 리소스 추가: `drawable/ic_notif_favorite.xml`, `ic_notif_favorite_outline.xml`.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과. 기기 알림 모양은 직접 확인 필요.

## 남은 일 · 질문
- 실제 기기에서 하트 · 기본 커버 모양 확인.
