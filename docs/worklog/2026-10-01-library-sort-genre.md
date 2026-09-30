# 보관함 정렬 드롭다운 · 장르별 보기

- 날짜: 2026-10-01
- 분류: 앱 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `feature/library-sort-genre` (`chore/rename-mulo` 위)
- 상세 기능: 보관함 정렬 · 장르별 보기

## 한 일
- 정렬: 알약 탭 대신 드롭다운(`AppDropdown`, 디자인 시스템에 추가). 이름순 · 추가일순 · 아티스트순.
- 장르별 보기: 보관함 탭에 "장르" 추가. 장르 목록(곡 수) → 누르면 그 장르 곡 목록(뒤로 가기 버튼). 장르를 모르는 곡은 "알 수 없는 장르"로 맨 뒤.
- 검색이 장르도 본다.
- 정렬 · 장르 묶기를 순수 함수로 분리(`domain/entities/library_sort.dart`: `sortTracks`, `groupByGenre`).
- 곡 타일을 `_songTile`로 묶어 곡 탭과 장르 안에서 같이 쓴다.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (정렬 · 장르 묶기 단위 3 + 위젯 1 추가), `flutter build apk --debug`.

## 남은 일
- 곡 타일 메뉴 · 가사 등은 다음 작업.
- 장르 안에서 재생 전체 · 섞기는 아직 없음 (보관함 전체 기준).
