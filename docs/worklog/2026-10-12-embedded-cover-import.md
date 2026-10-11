# 기기 음악 불러올 때 내장 커버 가져오기

- 날짜: 2026-10-12
- 분류: 앱
- 상태: 진행 중 (PR 확인 대기)
- 브랜치 · 커밋: `feature/library-embedded-cover`
- 상세 기능: 기기 음악 불러오기 (#11)

## 한 일
- 불러오기 뒤 커버가 없는 기기 곡에 파일 내장 커버를 붙인다 (D-101). 다시 불러오면 빈 커버도 채운다.
- Android `MediaStoreChannel`에 `embeddedPicture`, 데스크톱은 `audio_metadata_reader`로 읽고 512px로 줄여 저장.
- `FillEmbeddedCovers` 유스케이스, `EmbeddedCoverRepository`, `LibraryImportCubit`(`coversSeq`), 보관함 화면의 커버 다시 읽기.

## 바꾼 설정
- Kotlin: `MediaStoreChannel.kt`에 호출 하나 추가. pubspec · Manifest 변경 없음 (`audio_metadata_reader`는 이미 사용 중).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite` 성공.
- 실제 기기에서 내장 커버 있는 음원으로 확인은 아직.

## 남은 일 · 질문
- 곡이 아주 많은 폴더의 커버 채우기 시간은 기기에서 확인 필요.
