# 곡 타일 메뉴

- 날짜: 2026-10-01
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치: `feature/song-tile-menu` (`feature/theme-preview` 위, PR #22 다음)
- 상세 기능: 곡 타일 메뉴 (FD-48), 곡 메뉴 (FD-69, 같은 기능이 두 번 적혀 있음)

## 한 일
- 곡 줄의 ⋮ 버튼 · 길게 누르기 · 데스크톱 오른쪽 클릭이 **같은 곡 메뉴**(바텀 시트)를 연다. 보관함의 곡 목록(장르 안 곡 포함)과 홈의 최근 재생 · 많이 들은 곡 줄에 붙였다. 보관함 ⋮는 예전에는 커버 이미지 시트만 열었다.
- 항목 6개 (D-031):
  - **다음에 재생 · 대기열에 추가**: `NowPlayingCubit.playNext` · `addToQueue`. 대기열이 비어 있으면 그 곡을 바로 재생한다.
  - **재생목록에 추가**: PR #18의 다중 선택 대화상자(`showPlaylistPickerDialog`)를 그대로 쓴다. 이미 들어 있는 곡은 건너뛴다. 재생목록이 없으면 안내 문구만 띄운다.
  - **정보 편집**: 제목 · 아티스트 · 앨범 · 장르 대화상자. 제목이 비면 저장하지 않는다. 다시 불러와도 고친 값은 덮어쓰지 않는다. 재생 중인 곡이면 대기열(미니 플레이어)에도 바로 반영한다.
  - **커버 이미지 설정**: 기존 커버 시트(기기 사진 · 기본으로).
  - **삭제**: 확인 대화상자 후 보관함에서 지운다 (파일은 지우지 않는다).
- 구조: `TrackInfo`(domain), `LibraryRepository.updateInfo` · `delete`, 유스케이스 `UpdateTrackInfo` · `DeleteTrack`, `LibraryCubit`, `PlaylistsCubit.addTrack`, 화면은 `library/presentation/widgets/track_menu.dart`.
- 디자인 시스템: `MenuRow`(메뉴 한 줄, 삭제는 경고 색)를 `core/design/components/menu_row.dart`로 올리고 재생목록 설정 메뉴도 이것을 쓴다. `TrackTile`에 `onLongPress` · `onSecondaryTap`.
- 고친 문제 두 가지:
  - 곡은 id로만 같다고 보기 때문에 곡 정보를 고쳐도 `LibraryCubit` · `HomeBloc` 상태가 이전과 같다고 판단돼 화면이 갱신되지 않았다. 상태에 `revision`을 더하고 보관함 화면은 목록 대신 상태를 골라 읽는다.
  - `PlaylistsCubit`이 처음 읽을 때야 만들어져서 재생목록 탭을 열기 전 곡 메뉴에서는 목록이 비어 보였다. 앱 전체 `BlocProvider`에서 `lazy: false`로 바꿨다.

## 바꾼 설정
- 새 패키지 · 에셋 · 네이티브 변경 없음. drift 스키마 변경 없음.
- 문구(ko · en) 22개 추가 (`trackMenu*` · `trackEdit*` · `trackDelete*`).

## 확인
- `flutter analyze` 0, `flutter test` 통과, `flutter build apk --debug` 성공.
- 새 테스트: 저장소(정보 변경 · 재스캔 보존 · 삭제 연쇄), 대기열 조작(다음에 재생 · 추가 · 제거), 위젯(⋮ · 길게 누르기 · 오른쪽 클릭, 재생목록 담기, 편집, 삭제 확인 · 취소).
- 에뮬레이터 · 실기기에서의 직접 확인은 하지 않았다.

## 남은 일 · 질문
- 명세의 **가사 설정**(가사 직접 설정 · 로컬 가사)과 **파일 위치 보기**, 커버의 **웹에서 찾기**는 각각 별도 상세 기능이라 이번에 넣지 않았다. 해당 기능이 구현되면 메뉴에 항목을 더한다.
- 재생 엔진이 아직 없어 "다음에 재생 · 대기열에 추가"는 화면 상태(대기열)만 바꾼다.
- 삭제는 보관함 기록만 지운다. 기기에서 다시 불러오면 같은 파일이 다시 들어온다. 파일까지 지울지는 정하지 않았다 (되돌릴 수 없어 보류).
