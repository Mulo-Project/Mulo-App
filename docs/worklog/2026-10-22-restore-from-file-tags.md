# 파일 태그로 앱 DB 되살리기

- 날짜: 2026-10-22
- 분류: 기능
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/restore-from-file-tags` (develop 위)
- 상세 기능: 기기 음악 불러오기, 곡 정보 편집 (태그)

## 한 일
- `FileTagSource`(mp3 ID3 · opus/ogg Vorbis 코멘트 읽기), `FileTagRepository`, `TagRestoreStore`, `RestoreFromFileTags` 유스케이스 추가. 제목 · 아티스트 · 앨범 · 장르와 `COVER_SOURCE` · `COVER_TRANSFORM` · `COVER_COLOR`로 DB를 채움.
- `parseCoverExtra`(`coverExtra`의 되읽기), 불러오기 때 내장 커버 채우기 앞에 복원 실행.

## 바꾼 설정
- 없음 (pubspec · Gradle · Manifest 그대로, 기존 `audio_metadata_reader` · 기존 MethodChannel 재사용).

## 확인
`flutter analyze` 경고 0, `flutter test` 전체 통과 (새 `restore_from_tags_test.dart`). 실제 기기 읽기는 미확인.

## 남은 일 · 질문
- 앱 시작 때 자동 복원은 하지 않고 "기기 음악 불러오기" 때만 돈다.
