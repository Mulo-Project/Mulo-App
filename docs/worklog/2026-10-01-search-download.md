# 검색 탭에 다운로드 합치기

- 날짜: 2026-10-01
- 분류: 앱 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `feature/search-download` (`feature/home-tabs` 위, PR #11 의존)
- 상세 기능: 다운로드 대기열 (#7) · 키워드 검색 (#2)

## 한 일
- 다운로드 화면(탭 · 라우트 `/downloads` · 검색 화면 오른쪽 위 버튼)을 없애고 검색 탭에 합쳤다.
- 검색창 오른쪽에 검색 대상 메뉴: **유튜브 / 웹** (`SearchSource`). 웹 = yt-dlp가 지원하는 다른 음원 사이트(예: SoundCloud `scsearch`). 대상에 따라 입력칸 힌트가 바뀐다. 실제 검색 엔진 연결은 아직 (지금은 자리 표시 결과).
- 검색창 아래 **다운로드 카드** (`DownloadProgressCard`): 받는 곡의 썸네일을 배경으로 깔고 어두운 scrim(팔레트 `scrim`)을 덮었다. 썸네일 주소가 없거나 불러오기 실패하면 곡별 글로우 그라데이션. 받는 곡이 없으면 카드가 없다.
- 카드의 화살표(▾)로 **대기 중인 곡 목록**을 펼치고 접는다 (대기 · 일시정지 항목).
- 다운로드 기능(클린 아키텍처): `DownloadItem` · `DownloadStatus`, `DownloadQueueRepository`, `WatchDownloadQueue`, `DownloadQueueCubit`(앱 전체 provider), `di.dart`. 데이터는 `SampleDownloadQueueRepository`(자리 표시) — 다운로드 엔진이 붙으면 교체.
- `AppSearchField`에 `suffix`(항상 오른쪽에 보이는 위젯) 추가.

## 바꾼 설정 · 파일
- ARB: `searchHintWeb` · `searchSourceTooltip` · `sourceYoutube` · `sourceWeb` · `downloadsExpand` · `downloadsCollapse` 추가, `openDownloads` · `downloadsSubtitle` 삭제 (ko · en). 패키지 · Gradle · Manifest 변경 없음.
- 테스트 헬퍼: `MemoryDownloadQueue`, `setUpTestDependencies(downloads:)`.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (대기열 cubit 1 + 위젯 3: 카드 · 펼침 · 검색 대상 메뉴), `flutter build apk --debug`.
- 스크린샷 검색 화면(카드 포함).

## 남은 일
- 받기 팝업(제목 · 아티스트 · 장르 · 대상 재생목록)은 다음 작업.
- 일시정지 · 재시도 · 취소 · 완료 지우기는 다운로드 엔진 연결 때 카드/대기열에 붙인다 (문구는 ARB에 남겨 둠).
- 웹 검색(`scsearch` 등)은 엔진 연결 때.
