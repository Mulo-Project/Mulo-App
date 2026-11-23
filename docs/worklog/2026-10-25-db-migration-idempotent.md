# DB 마이그레이션 멱등화 (duplicate column name 수정)

- 날짜: 2026-10-25
- 분류: 앱 (수정)
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `fix/migration-duplicate-column` (기반: `chore/overall-performance`)
- 상세 기능: 앱 로컬 DB (공통)

## 한 일
- 증상: 폰에서 `SqliteException(1) duplicate column name: sort_order`로 DB가 안 열려 보관함 · 기기 음악 불러오기가 모두 실패. 폰 DB에 열은 이미 있는데 버전이 낮아 10 → 11 업그레이드가 다시 돌았다 (빌드를 번갈아 설치한 경우 등).
- `onUpgrade`의 모든 `addColumn`을 `_addColumnIfMissing`(PRAGMA table_info로 열 확인)으로 바꿔 다시 돌아도 실패하지 않게 했다.
- `beforeOpen`에서 이미 11인데 열이 빠진 DB(covers의 url · scale · dx · dy · rotation, playlists.sort_order)를 채운다. 앱 데이터 삭제는 필요 없다.

## 바꾼 설정
- 없음 (스키마 버전 11 그대로, 생성 코드 변경 없음).

## 확인
- `test/core/app_database_migration_test.dart` 추가: 열이 이미 있는 10 · 8 버전 DB 열기, 11인데 sort_order가 빠진 DB 열기. 수정 전에는 3개 모두 같은 오류로 실패, 수정 후 통과.
- `flutter analyze`: 내 변경은 경고 0 (작업 폴더의 추적되지 않은 `_measure_test.dart`만 오류, 이 작업과 무관). 전체 `flutter test`에서 `engine_download_queue_test` 1건이 한 번 실패했으나 단독 실행은 통과 (순서 의존으로 보임).

## 남은 일 · 질문
- 폰에서 실제 확인은 이 PC에서 못 했다. 앱을 새로 설치(업데이트)하면 기존 데이터로 열려야 한다.
