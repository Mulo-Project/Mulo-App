# 재생목록별 받기 진행 · 받기 전체 취소

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료 (merge 대기)
- 브랜치 · 커밋: `feature/playlist-download-progress`
- 상세 기능: 다운로드 대기열 (#7), 유튜브 재생목록 가져오기 (#22)

## 한 일
- `CancelAllDownloads` 유스케이스 · `DownloadQueueRepository.cancelAll({playlistId})` · `DownloadQueueCubit.cancelAll`.
- 상태에 `unfinishedCount` · `unfinishedFor(playlistId)` · `overallProgress`를 더하고 `waiting`은 뺐다.
- 재생목록 상세에 "받는 중 N곡" 구역(곡별 진행 · 취소 · 다시 받기, 이 재생목록 전체 취소).
- 재생목록 가져오기를 시작하면 만든 재생목록 상세로 바로 이동 (전에는 이전 화면으로 돌아갔다).
- 검색 탭 받기 카드를 현재 곡 + 전체 진행 + 전체 취소로 줄임.
- ARB: `downloadsCancelAll` · `downloadsCancelAllTitle` · `downloadsCancelAllBody` · `downloadsOverall` · `playlistDownloadsTitle` (ko · en).

## 바꾼 설정
- 없음 (pubspec · 네이티브 변경 없음).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (카드 · 전체 취소 · 재생목록 상세 위젯 테스트 추가).

## 남은 일 · 질문
- 결정 번호 D-080는 develop의 다음 번호로 썼다. 다른 PR과 겹치면 병합할 때 번호를 올린다.
