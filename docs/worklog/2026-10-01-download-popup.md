# 받기 팝업 · 장르

- 날짜: 2026-10-01
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치: `feature/download-popup` (`feature/search-download` 위, PR #12 의존)
- 상세 기능: 다운로드 (#7) · 곡 정보 편집 · 재생목록 담기

## 한 일
- **받기 팝업** (`showDownloadDialog`, 바텀시트): 받기를 누르면 열리고 제목 · 아티스트 · 장르를 고친 뒤 "받기"로 대기열에 넣는다. 제목이 비면 버튼이 꺼진다. 저장할 때 넣을 **재생목록을 여러 개** 고를 수 있고(스위치), 목록에 없으면 팝업 안에서 새로 만들 수 있다(만들면 자동 선택).
- 검색 탭 연결: URL 결과 카드의 받기 · 키워드 결과의 받기 아이콘이 팝업을 연다. 결과의 제목 · 아티스트가 입력칸 초기값. 시작하면 "대기열에 넣었어요" 안내.
- **장르**: `Track.genre`(모르면 빈 문자열), drift `tracks.genre` 열, `DownloadItem.genre` · `DownloadRequest.genre`.
- **재생목록 기능 시작** (`features/playlists`): 엔티티 `Playlist`, `PlaylistRepository`(구독 · 만들기 · 곡 넣기), 유스케이스 3개, `PlaylistsCubit`(앱 전체 provider), drift 구현. 재생목록 탭 화면은 아직 자리 표시 데이터 그대로.
- **다운로드**: `DownloadRequest`, `DownloadQueueRepository.enqueue`, `EnqueueDownload`(제목 비면 거부 · 공백 정리), `DownloadQueueCubit.enqueue`. 자리 표시 대기열은 새 요청을 "대기" 항목으로 끝에 붙인다(실제로 받지는 않음).
- **홈 청취 분석에 장르**: `ListeningStats.topGenres`(`GenrePlays`), 카드에 "많이 들은 장르". 장르를 모르는 곡은 세지 않는다. (PR #11에서 장르가 없어 뺀 것.)
- 디자인 시스템에 `AppTextField`(라벨이 위에 붙은 입력칸) 추가.

## 바꾼 설정 · 파일
- DB 스키마 2 → 3: `tracks.genre` 열 추가, `playlists` · `playlist_tracks` 표 추가 (마이그레이션 포함). `app_database.g.dart` 재생성.
- ARB(ko · en): `downloadDialogTitle` · `downloadFieldTitle/Artist/Genre` · `downloadPlaylistsLabel` · `downloadPlaylistsEmpty` · `downloadNewPlaylist(Hint)` · `downloadQueued` · `homeTopGenre`. 패키지 · Gradle · Manifest 변경 없음.
- 테스트 헬퍼: `MemoryPlaylistRepository`, `MemoryDownloadQueue.enqueue/requests`, `setUpTestDependencies(playlists:)`.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (재생목록/장르 drift 3 · 받기 요청 유스케이스 1 · 팝업 위젯 2 · 홈 장르 통계 1 추가), `flutter build apk --debug`.

## 남은 일 · 질문
- 받기가 끝나 곡이 보관함에 들어올 때 `DownloadItem`의 `genre` · `playlistIds`로 `Track.genre`를 채우고 `AddTrackToPlaylists`를 부르는 일은 **다운로드 엔진 연결 때** 한다(지금은 엔진이 없어 곡이 생기지 않음).
- 재생목록 탭을 실제 DB(`PlaylistsCubit`)로 바꾸는 것, 기기에서 불러온 곡의 장르(MediaStore) 채우기, 곡 정보 수정 화면은 다음 작업.
- 재생목록 URL의 "선택한 곡 받기"는 곡이 여러 개라 팝업 없이 그대로 둠(일괄 받기 설계 때 정한다).
