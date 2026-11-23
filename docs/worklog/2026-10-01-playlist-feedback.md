# 재생목록 피드백 반영 (대표곡 · 팝업 메뉴 · 상세 · 좋아요)

- 날짜: 2026-10-01
- 분류: 앱 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `feature/playlist-feedback` (`ui/common-feedback` 위, PR #25 다음)
- 상세 기능: 재생목록 관리 (#20) · 공통 (사용자 피드백 2026-10-01)

## 한 일
- **카드**: 곡 3개 요약 대신 **대표곡 하나를 크게** (많이 들은 곡, 없으면 먼저 담은 곡). ⋮ 버튼 · 길게 누르기 · 오른쪽 클릭이 같은 팝업 메뉴를 연다.
- **팝업 메뉴** (`showPlaylistMenu`): 전체 재생 · 카드 색(하위 팝업, 색 아이콘 + 이름) · 이미지(별도 팝업) · 이름 바꾸기 · 삭제.
- **만들기**: 이름 + 카드 색 + 이미지 고르기.
- **곡 담기**: 곡 메뉴 "재생목록에 추가"가 재생목록 화면(`/playlists/pick`)으로 이동 → 카드 선택 → 완료.
- **좋아요 목록**: 항상 맨 앞, 곡 메뉴에서 켜고 끈다.
- **별도 페이지**: 재생목록 상세(`/playlists/:id`) · 앨범(`/library/album`) · 재생 대기열(`/queue`). 상세의 곡 메뉴는 "재생목록에서 빼기" · "파일 삭제".
- 디자인 시스템: `AppMenuItem`에 `iconColor` · `selected`, `ArtworkBox`에 `width`.
- 곡 한 줄을 `TrackListTile`로 합침 (보관함 · 상세 · 앨범).
- 구조: 도메인 `watchTracks` · `rename` · `delete` · `addTracks` + 유스케이스, `PlaylistsCubit`(좋아요 · 이름 · 삭제), `PlaylistTracksCubit`, `CoverCubit.pickFile`/`setFromFile`.

## 바꾼 설정
- drift 스키마 변경 없음 (좋아요는 id `favorites`인 가상 재생목록). 새 패키지 · 에셋 · 네이티브 변경 없음.
- 문구(ko · en) 추가: `playlistFavorites` · `playlistMenu*` · `playlistImage*` · `playlistRename*` · `playlistDelete*` · `playlistPick*` · `playlistDetailEmpty` · `playlistNotFound` · `albumNotFound` · `playerQueueEmpty` · `trackMenuFavorite` · `trackMenuUnfavorite` · `trackFavorite*`.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (새 테스트: 카드 · 메뉴 · 색/이미지 하위 팝업 · 이름 바꾸기 · 삭제 · 만들기(색/이미지) · 상세 · 전체 재생 · 담기 화면 · 좋아요 · 앨범 · 대기열 · 저장소 `watchTracks`/`rename`/`delete`/대표곡/좋아요).
- 스크린샷 테스트로 재생목록 화면 레이아웃(대표곡 카드)을 확인했다. 실기기 · 에뮬레이터 확인은 하지 않았다.

## 남은 일 · 질문
- 재생목록 곡 순서 바꾸기(드래그)는 아직 없다 (담은 순서).
- 대기열 화면은 보기 · 곡 선택만 (대기열 편집 #16은 이후).
- 앨범 화면 커버는 곡 커버 대신 기본 그라데이션이다.
