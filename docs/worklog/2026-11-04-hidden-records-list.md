# 숨긴 곡 기록 정리: 목록 시트

- 날짜: 2026-11-04
- 분류: 설정 · 보관함

## 해석
설정 > 데이터의 '숨긴 곡 기록 정리'는 전에는 누르면 숨긴 곡의 기록을 한꺼번에 지우는 확인창만 있었다.
"숨긴 곡 기록을 정리/관리하는 화면"으로 보고, 눌렀을 때 숨긴 곡 목록 시트를 열어 곡마다 지우기와 모두 지우기를 고르게 했다.

## 바뀐 것
- `LibraryRepository.hiddenTracks()` 추가, `purgeHidden({ids})`로 고른 숨긴 곡만 지울 수 있게 함 (보이는 곡은 ids에 있어도 건드리지 않음).
- 유스케이스 `CountHiddenTracks` → `ListHiddenTracks`, `PurgeHiddenTracks`는 곡 id 집합(null이면 모두).
- `HiddenRecordsCubit` 상태가 숨긴 곡 목록이 됨 (개수는 길이).
- 바텀 시트 `hidden_records_sheet.dart`: 곡 · 아티스트 줄 + 지우기(X), 아래 '모두 지우기'. 지우기 전 확인창.
- 문구(ARB 2종)와 생성된 l10n 코드 추가.

## 확인 (PC에서 필요)
`dart format .` · `flutter analyze` · `flutter test`. 클라우드에서 만들어 빌드/테스트는 돌리지 못했다.
