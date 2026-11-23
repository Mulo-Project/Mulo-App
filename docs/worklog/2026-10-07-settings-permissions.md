# 설정 권한 묶음

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `feature/permissions-settings`
- 상세 기능: 공통 작업 (설정)

## 한 일
- `features/permissions/` 추가 (domain · data · presentation · di). `PermissionsCubit`이 권한별 상태를 읽고, 토글을 누르면 요청 창 또는 시스템 설정을 연다 ([D-086](../decisions.md)).
- 설정 목록의 알림 묶음 아래에 "권한" 묶음 (`PermissionsSection`). 문구는 ARB(ko · en).

## 바꾼 설정
- 없음 (기존 `permission_handler` 사용, 매니페스트 변경 없음).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (`permissions_cubit_test` 추가).

## 남은 일 · 질문
- 백그라운드 받기 토글은 다른 작업에서 추가 중. 생기면 알림 권한 줄 설명에서 연결.
