# 숨긴 곡 기록 정리 전에 목록 보여 주기

- 날짜: 2026-11-03
- 분류: 기능 (Android 네이티브 리팩터링 브랜치에 같이 담음)
- 상태: 완료 (빌드 · 실기기 확인 전)

## 한 일
- 설정 > 데이터 > 숨긴 곡 기록 정리: 누르면 숨긴 곡 목록 시트를 먼저 보여 주고, "기록 지우기"를 눌러야 확인 창 → 삭제.
- `hiddenTracks()` · `ListHiddenTracks` 추가, `HiddenRecordsCubit.tracks()`, `hidden_records_sheet.dart`, ARB 2줄 (`hiddenRecordsHint` · `hiddenRecordsPurge`).
- `app_localizations*.dart`는 `flutter gen-l10n`을 못 돌려 손으로 같은 줄을 더했다. PC에서 `flutter gen-l10n`을 한 번 돌려 차이가 없는지 확인한다.

## 확인할 것
- `flutter analyze` · `flutter test`, 시트에서 닫기 / 기록 지우기 두 경로.
