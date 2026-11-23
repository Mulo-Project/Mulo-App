# 재생목록 카드의 받기 진행

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `feature/playlist-card-download-progress`
- 상세 기능: 다운로드 대기열 (#7), 유튜브 재생목록 가져오기 (#22)

## 한 일
- `DownloadQueueState.activeFor(playlistId)`: 카드에 보일 곡 (받는 중 > 대기 > 일시정지, 실패만이면 null).
- `PlaylistCard`의 대표곡 칸이 받는 중이면 곡 제목 · `ProgressLine` · 상태(%)를 보인다.
- 위젯 테스트 추가.

## 바꾼 설정
- 없음 (pubspec · 네이티브 변경 없음, ARB 문구 추가 없음).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과.
