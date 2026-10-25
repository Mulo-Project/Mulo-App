# 보관함 다중 선택 · 앨범 · 아티스트 · 장르 일괄 지정

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `feature/library-multi-select` (기반: `chore/overall-performance`)
- 상세 기능: 보관함 (곡 정보 편집 · 재생목록 추가)

## 한 일
- 보관함 곡 탭: 곡 줄 길게 누르기 → 선택 모드 (D-123). 팝업 메뉴는 줄의 ⋮로만 연다.
- 선택 모드 하단 막대(`LibrarySelectionBottomBar`): 선택 수, 닫기, 모두 선택 · 해제, "작업" 버튼. 누르면 바텀 시트(`showSelectionActionSheet`)에 재생목록에 추가 · 앨범 · 아티스트 · 장르 지정이 나온다.
- 일괄 지정(`assignToSelection`): 값 입력 → "고른 N곡의 앨범이 A(으)로 바뀌어요" 확인 → 곡마다 태그 먼저 쓰고 DB (D-120, `LibraryCubit.assignGroup`).
- `TrackTile`에 `onLongPress`, `TrackListTile`에 `selection`(`TrackSelection`)을 더해 다른 목록은 그대로 두었다.
- ARB 문구(ko · en) 추가, `track_menu_test`의 길게 누르기 · 오른쪽 클릭 확인을 보관함 규칙에 맞게 고침.

## 바꾼 설정
- 없음 (패키지 · Gradle · Manifest 변경 없음).

## 확인
- `flutter analyze` 경고 0, `flutter test` 전체 통과. `test/features/library/library_multi_select_test.dart` 3건 추가 (선택 모드 진입 · 해제, 장르 일괄 지정, 확인창 취소).
- 실제 기기에서 ffmpeg 태그 쓰기는 이 PC에서 확인하지 못했다 (D-120과 같음).

## 남은 일 · 질문
- 앨범 · 아티스트 · 장르 화면, 재생목록 상세로 선택 모드를 넓힐지.
- 일괄 삭제는 되돌릴 수 없어 이번에 넣지 않았다.
