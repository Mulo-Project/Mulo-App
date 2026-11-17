# 받기 큐 · 실행을 네이티브로 (D-167)

- 날짜: 2026-11-17
- 분류: 앱
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `fix/release-r8-workmanager-keep` (PR #176)
- 상세 기능: 다운로드 대기열

## 한 일
- 받기 큐(대기열 · 일시정지 · 이어받기 · 재시도 · 취소)와 받기 실행(주소 읽기 · 조각 이어받기 · HLS · mp3 변환 · 가사 · 태그 · MediaStore 저장 · 보관함 등록)을 Dart에서 Kotlin `DownloadEngine`으로 옮겼다. 앱 화면 없이 포그라운드 서비스 안에서 끝까지 돈다.
- 보관함 DB는 네이티브가 같은 SQLite 파일(`AppDb`)에 곡 · 재생목록 · 커버 · 색 · 가사 행을 직접 쓴다. 스키마 · 마이그레이션은 계속 Dart(drift). 파일이 없거나 버전이 낮으면 `pending_register.json`에 맡겨 두었다가 앱이 DB를 연 뒤 등록한다.
- 받기 알림(진행 · 결과 · 다시 시도)을 네이티브가 만든다. Dart는 글과 설정만 `configure`로 넘긴다 (`{p}` `{d}` `{n}` `{t}` `{f}` 자리표시). 알림의 취소 · 일시정지 · 다시 시도 버튼은 `DownloadActionReceiver`가 앱 없이 바로 처리한다 . 미리 듣기 · 미리 듣기 멈춤 버튼도 `PreviewChannel`을 네이티브에서 바로 불러 처리하고, 상태가 바뀌면 Dart에는 `changed`만 알린다 (Dart가 끼지 않는다).
- Dart는 `NativeDownloadQueueRepository`가 요청을 넘기고 네이티브가 알리는 상태(`queue` 이벤트)를 그린다. 옛 `EngineDownloadQueueRepository` · `AudioFileDownloader` · `AudioTranscoder`와 그 테스트는 지웠다.
- 앱 DB를 WAL + busy_timeout으로 열도록 했다 (`AppDatabase`).

## 바꾼 설정
- Kotlin: `DownloadEngine` · `DownloadChannel`(`music_app/downloads`) · `AppDb` · `SubtitleLrc` 추가, `MuloEngine` · `DownloadActionReceiver` · `TagChannel`(`writeBlocking`) · `TranscoderChannel`(`convertAudio` · `cancelProcess`, full/lite) · `MediaStoreChannel`(`saveAudio` 공개) · `YtDlpEngineChannel`(엔진 공개) 수정.
- 의존성 · Manifest 변경 없음.

## 확인
- 클라우드에서는 빌드 · 테스트를 못 했다. 사용자가 PC에서 `flutter analyze` · `flutter test` · 기기 확인.

## 남은 일 · 질문
- 영상 저장 시 `VideoSaveRepository.save`(Dart)와 `DownloadedFileStore` 일부는 이제 받기에 쓰이지 않는다 (정리 대상).
- 데스크톱(Windows 등)에서는 네이티브 받기가 없어 받기를 쓸 수 없다 (Android 우선).

## 추가 정리: 남은 Dart 기능을 네이티브로 (같은 PR)

- 영상 저장 Dart 경로(`YtDlpVideoSaveRepository`), 파일 저장(`DownloadedFileStore`), 태그 쓰기 도우미(`CoverTagWriter`), `NativeYtDlp.saveVideo`를 지웠다. 받기 큐(`DownloadEngine`)가 이미 같은 일을 한다. `VideoSaveRepository`는 지원 여부(`isAvailable`)만 남았다.
- 태그 쓰기: Dart는 값(null 가능) · 커버 파일/주소 · 커버 색만 `music_app/tags`의 `write`에 넘긴다. 빈 칸 거르기, `COVER_COLOR` 만들기, 커버 이미지 받기는 `TagChannel`이 한다. `read`는 커버 색(`color`)까지 해석해 돌려준다.
- 가사 읽기: `music_app/lyrics`의 `read`(uri → 글)로 바꿨다. mp3는 `Id3Lyrics`(USLT · TXXX, Kotlin), 그 밖의 형식은 `TagReader`의 `lyrics` 칸. Dart의 ID3 바이트 파서(`Id3TxxxLyrics`)와 `audio_metadata_reader` 가사 읽기를 없앴다.
- 남김: `DownloadQueueStore`(옛 대기열을 네이티브로 한 번 넘기는 이전용), drift 보관함 DB(스키마 주인).

