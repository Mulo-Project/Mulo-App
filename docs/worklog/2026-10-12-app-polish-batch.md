# 앱 다듬기 묶음 (13건)

- 날짜: 2026-10-12
- 분류: 앱 · 디자인
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `fix/app-polish-batch`
- 상세 기능: 공통 작업 (보관함 · 재생목록 · 알림 · 테마 · 앱 잠금)

## 한 일
[D-098](../decisions.md) 참고. 항목: 웹 이미지 기본 검색어 · 대기열 "빼기" 메뉴 · 받기 줄 접기 렉 · 테마 전환 렉 · 라이트 테마 색 · 숨김 알림 순번 · 곡 순번 표시 · 앱 잠금 재잠금 · 받기 알림 클릭 → 상세 · 보관함 셔플 · 보관함 탭별 정렬 · 대기열 메뉴 정리 · 곡 분위기 따라가기.

## 바꾼 설정
- 코드: Dart 전반 + Kotlin(`DownloadNotifications` · `DownloadNotificationPlugin` · `MainActivity` · `SessionPlayer`). 패키지 · Gradle · Manifest 변경 없음.
- ARB: `sortCount` · `trackMenuRemoveFromQueue` · `trackRemovedFromQueue` · `notifHiddenNotePosition`.
- 저장 키: `theme.followMood` (shared_preferences).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite`.
- 기기 확인: PR 본문의 테스트 목록.

## 남은 일 · 질문
- Notion 작업 기록 갱신.
