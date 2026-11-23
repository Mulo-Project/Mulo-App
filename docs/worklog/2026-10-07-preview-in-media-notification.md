# 미리 듣기를 재생 알림에 합치기

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료 (merge 대기)
- 브랜치 · 커밋: `feature/preview-in-media-notification`
- 상세 기능: 알림 (재생 알림)

## 한 일
- 미리 듣는 동안 재생 알림을 미리 듣는 곡으로 바꿔 보이고(줄 앞에 "미리 듣기"), 끝나거나 멈추면 앞에 듣던 곡으로 돌린다 ([D-088](../decisions.md)).
- `NotificationSyncCubit.syncPlayback`에 `preview`(PreviewNotice)를 더했고, `NotificationBridge`가 `PreviewCubit`을 듣고 미리 듣는 중에는 알림의 멈추기 · 이동을 미리 듣기로 보낸다.
- 앱 안 미리 듣기 줄(`PreviewMiniBar`)에 강조색 배경 · 테두리를 줬다.

## 바꾼 설정
- 새 패키지 · 권한 없음. 문구 `notifPreviewLabel`(ko · en) 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (미리 듣기 알림 테스트 4개 추가).
