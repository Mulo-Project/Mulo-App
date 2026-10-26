# 저장한 가사를 파일에 쓰기 (일괄)

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `feature/lyrics-bulk-write-to-file` (기반: `develop`)
- 상세 기능: 가사 (설정 · 싱크 저장 시 파일 태그 쓰기의 후속)

## 한 일
- 설정 › 재생에 "저장한 가사를 파일에 쓰기" 줄 추가 (`SettingsLyricsFileRow`): 대상 곡 수 확인 대화상자 → 진행 대화상자 → 결과 대화상자(쓴 · 같아서 건너뛴 · 쓸 수 없어 건너뛴 · 실패한 곡 수). 앱에 저장한 가사가 없으면 안내만 한다.
- `LyricsRepository`에 `savedTrackIds()` · `loadSaved()` 추가 (앱에 직접 저장한 가사만, 옆 `.lrc` · 태그 가사 제외).
- 유스케이스 `CountSavedLyricsTracks` · `WriteSavedLyricsToFiles`, `LyricsFileWriteCubit`. 파일 태그에 같은 가사가 있으면 건너뛰고, 다르면 기존 `TrackTagRepository.writeLyrics`로 쓴다. 앱 가사는 읽기만 한다 (D-128).
- `showProgressWhile`에 제목 · 진행 문구 바꾸기(`title` · `count`) 추가. ARB `lyricsToFile*`(ko · en).
- `test/widget_test.dart`의 설정 화면 높이를 8000 → 9000으로 늘렸다 (설정이 길어져 테마 줄이 하단 막대에 가려짐).

## 바꾼 설정
- 패키지 · Gradle · Manifest 변경 없음. 새 네이티브 채널 없음.

## 확인
- `flutter analyze` 경고 0, `flutter test` 전체 통과. `test/features/lyrics/write_saved_lyrics_to_files_test.dart`(대상 수 · 쓰기 · 건너뛰기 · 실패 시 앱 가사 유지 · 전부 쓸 수 없음), `lyrics_file_write_widget_test.dart`(설정 흐름) 추가.
- 실제 기기에서 가사 태그 쓰기(`content://` 덮어쓰기 포함)와 lite · 데스크톱 안내 문구는 이 PC에서 확인하지 못했다.

## 남은 일 · 질문
- 쓸 수 없는 환경을 미리 가르지 않고 곡별 결과로 안내한다. 확인창 전에 막고 싶으면 `TrackTagRepository`에 "쓸 수 있는가" 조회를 더해야 한다.
