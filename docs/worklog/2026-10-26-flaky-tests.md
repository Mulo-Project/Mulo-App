# 불안정한 테스트 안정화

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `fix/flaky-tests` (기반: `develop`)
- 상세 기능: 공통 작업 (테스트)

## 한 일
- 전체 테스트를 CPU 부하 + 병렬로 반복 실행해 재현하고 원인을 찾았다 (D-130).
- `loopback_google_auth.dart`: 코드 대기 Future를 만든 직후 `ignore()` (처리되지 않은 오류 방지, 동작 동일).
- `engine_download_queue_test.dart`: `tearDown`의 폴더 삭제를 재시도, 고정 50ms 대기를 `until`(조건 대기)로 교체.
- 테마 프리셋 테스트는 재현되지 않아 바꾸지 않았다.

## 바꾼 설정
- 없음.

## 확인
- `flutter analyze`, 반복 `flutter test` 결과는 PR 본문에 적었다.

## 남은 일 · 질문
- 테마 프리셋(widget_test)과 극심한 부하(수 초씩 걸리는 환경)에서의 로그인 테스트 연결 끊김은 원인을 못 찾았다. 다시 보이면 실패 로그를 남긴다.
