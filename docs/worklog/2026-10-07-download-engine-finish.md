# 다운로드 엔진 마무리: mp3 · 음질, 이어받기, 대기열 저장, 이미 받은 곡 건너뛰기

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료 (PR 대기, 기기 확인 대기)
- 브랜치 · 커밋: `feature/download-engine-finish`
- 상세 기능: 오디오 추출 저장 (#5), 음질 선택 (#6), 다운로드 대기열 (#7), 기본 음질 · 포맷 설정 (#24), 유튜브 재생목록 가져오기 (#22)

## 한 일
- 결정은 D-074. 설정의 기본 음질 · 포맷을 저장하고(`DownloadPreferencesCubit`), 받은 뒤 mp3 · 낮은 음질 opus로 바꾼다 (`AudioTranscoder` → Android `TranscoderChannel`, full 빌드의 ffmpeg).
- 이어받기: `HttpAudioFileDownloader`가 받다 만 파일 뒤부터 `Range`로 이어 받는다 (형식 확인 · 416 · 구간 무시 서버 처리). 일시정지 · 실패 때 임시 파일을 남기고, 완료 · 취소 때 지운다.
- 대기열 저장: `DownloadQueueStore`(shared_preferences JSON). 앱을 다시 켜면 받던 곡을 이어 받는다. 임시 파일은 앱 전용 폴더로 옮겼다.
- 이미 받은 곡 건너뛰기: `downloadSourceKey` · `findExisting` · `FindExistingDownload`. 재생목록 가져오기가 받은 곡은 건너뛰고 새 재생목록에만 담는다 (안내 문구 추가). #69(재생목록 가져오기) 브랜치를 합쳐서 이어 만들었다.
- `DownloadRequest.quality`는 null이면 설정값, `format` 추가. 받기 팝업의 음질 인자도 null 기본.

## 바꾼 설정
- Android `app/build.gradle.kts`: `fullImplementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")` 추가 (full 빌드만, APK 커짐).
- Android 새 파일: `full/…/TranscoderChannel.kt`(ffmpeg 실행), `lite/…/TranscoderChannel.kt`(빈 구현), `MainActivity.kt`에서 채널 등록 · 해제. Manifest · pubspec 변경 없음, 새 Dart 패키지 없음.

## 확인
- `flutter analyze` 경고 0, `dart format`, `flutter test` 통과. 새 시험: Range 이어받기 5가지(이어 받기 · 표시 없음 · 다른 형식 · 416 · 구간 무시), 일시정지 → 이어받기, 대기열 저장 → 재시작 이어받기, 일시정지 상태 유지, mp3 · opus 변환 · 변환기 없음 · 기본은 변환 안 함, 이미 받은 곡 찾기, 재생목록 가져오기 건너뛰기, 주소 키, JSON 왕복.
- 기기에서는 확인하지 못했다: ffmpeg 실행(`libffmpeg.so` + `LD_LIBRARY_PATH`)과 mp3 변환, 실제 서버의 이어받기.

## 남은 일 · 질문
- full 빌드 APK 크기가 커진다 (ffmpeg 모듈). ABI 분할 · 릴리스 크기 줄이기를 정해야 한다.
- 변환 중 별도 상태 표시(변환 중…)는 없다. 서버 모드(lite)의 변환은 서버 쪽 일이다.
- 곡 하나를 직접 받을 때는 이미 받은 곡이어도 막지 않는다 (확인 대화상자를 붙일지 정해야 한다).
