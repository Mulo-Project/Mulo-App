# 곡 정보를 파일 태그에 넣기

- 날짜: 2026-10-22
- 분류: 앱
- 상태: 완료 (진행률 표시 · mp3 가사 · opus 태그는 남음)
- 브랜치 · 커밋: `feature/embed-file-tags`
- 상세 기능: 다운로드 · 보관함 (결정 D-110)

## 한 일
- 받을 때 제목 · 아티스트 · 장르 · 가사 · 커버를 mp3 · m4a 태그에 쓰도록 `CoverTagWriter` 확장.
- 곡 정보 편집 시 DB 저장 뒤 파일 태그에도 쓰기 (`UpdateTrackInfo` + `TrackTagRepository`).
- Android `content://` 파일 덮어쓰기: `MediaStoreChannel.overwriteAudio` (복사 → 태그 → 덮어쓰기).
- 기존 받은 곡 백그라운드 이관 `EmbedTagsIntoFiles` (앱 시작 5초 뒤, 곡마다 기록해 이어서).

## 바꾼 설정
- Android `MediaStoreChannel.kt`에 `overwriteAudio` 메서드. 권한 · 의존성 변경 없음.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (이관 · 편집 태그 쓰기 단위 테스트, mp3 태그 쓰기 테스트).
- 기기에서 `content://` 덮어쓰기는 아직 실제 Android 기기로 확인하지 못했다.

## 남은 일 · 질문
- mp3 가사(USLT)는 라이브러리가 못 써서 제외. opus · ogg 태그(ffmpeg), 이관 진행률 표시.
