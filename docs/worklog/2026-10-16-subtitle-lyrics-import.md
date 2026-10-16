# 유튜브 자막을 가사로 가져오기

- 날짜: 2026-10-16
- 분류: 앱
- 상태: 진행 중 (브랜치 `feature/lyric-sync-extras`에서 가사 테마 · 시간 보정과 함께 PR 예정)
- 브랜치 · 커밋: `feature/lyric-sync-extras`

## 한 일
- 엔진에 `fetchSubtitles` 추가: 로컬(yt-dlp 자막 받기 + WebVTT 읽기), 서버(`/api/v1/subtitles` 제안 형식), 나머지 덮개는 안쪽 엔진에 넘김. 곡 정보에 `subtitleLangs`.
- 받기 팝업에 `자막을 가사로 가져오기` 스위치, `DownloadRequest.importLyrics`(대기열 저장에도 포함).
- 받기가 끝나면 대기열 저장소가 자막을 `.lrc`로 저장. 실패해도 받기는 성공. 결정은 D-109.

## 바꾼 설정
- pubspec · Gradle · Manifest 변경 없음. 새 문구 3개(ARB ko/en).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (VTT 읽기 · 언어 고르기 · 로컬/서버 엔진 · 대기열 저장 · 팝업).
- 실제 유튜브 영상으로 yt-dlp 자막 받기는 아직 기기에서 확인하지 못했다.

## 남은 일 · 질문
- 서버 저장소에 `/api/v1/subtitles` 와 `/info`의 `subtitleLangs`를 추가해야 서버 모드에서 동작한다 (형식은 D-109).
- 받기가 끝났을 때 "가사를 가져왔어요" 안내는 아직 없다.
