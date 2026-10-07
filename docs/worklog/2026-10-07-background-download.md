# 백그라운드 받기 설정과 받기 알림 개편

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/background-download-notification`
- 상세 기능: 알림 (받기 진행)

## 한 일
- 포그라운드 서비스를 알림 설정에서 분리해 설정 > 알림에 "백그라운드 받기" 토글을 더했다 (`NotificationSettings.backgroundDownload`, 기본 켬).
- 받기 알림에 지금 곡 · 다음 곡 · 전체 진행률(곡 수 + 막대)과 미리듣기 버튼을 더했다. 버튼은 지금 받는 곡을 미리 듣기로 튼다.
- 결정: D-085.

## 바꾼 설정
- 없음 (새 패키지 · Manifest 변경 없음). 문구는 ARB(ko · en)에 추가, `notifDownloadProgressMore`는 `notifDownloadProgressNext`로 바꿨다.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (알림 동기화 테스트에 전체 진행 · 숨기기 · 백그라운드 설정 케이스 추가). 실기기 확인은 아직.

## 남은 일 · 질문
- 실기기에서 최근 앱 닫기 후 받기 지속, 미리듣기 버튼 동작 확인.
- 앱을 열지 않고 알림에서만 듣기는 하지 않았다 (D-085).
