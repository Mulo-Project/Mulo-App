# 다운로드 엔진 연결: 대기열이 실제로 받아 보관함에 담는다

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 진행 중 (PR 열어 둠, 기기 확인 대기)
- 브랜치 · 커밋: `feature/download-engine`
- 상세 기능: 오디오 추출 저장 (#5), 다운로드 대기열 (#7), 곡 정보 편집 · 재생목록에 담기 (받기 팝업이 정한 값을 곡에 적용)

## 한 일
- `MemoryDownloadQueueRepository`(받는 시늉만 하던 대기열)를 `EngineDownloadQueueRepository`로 바꿨다. 한 곡씩 차례로: 주소 해석(`DownloaderEngine.resolveAudioStream`, 미리 듣기와 같은 경로) → 구간 요청 받기 → 음악 폴더 저장 → 보관함 곡 · 재생목록 · 커버 · 색. 결정은 D-069.
- `HttpAudioFileDownloader`(data/datasources): 10MB씩 `Range` 요청, 구간마다 2번 재시도, 403 · 404 · 410은 다음 형식 주소(`fallbacks`)로, 진행률 · 취소 표시(`DownloadCancelToken`).
- `PlatformDownloadedFileStore`: Android는 MediaStore(`saveAudio`, Kotlin `MediaStoreChannel`)에 저장해 `content://` 주소를 얻고, 그 밖의 OS는 폴더로 옮긴다.
- 실패 · 재시도 · 취소: 실패하면 카드에 `실패 · <까닭>`과 "다시 시도" 버튼(`RetryDownload` 유스케이스 추가), 취소는 목록에서 빼고 임시 파일을 지운다. 일시정지는 멈춘 뒤 처음부터 다시 받는다.
- `DownloadRequest.url` · `DownloadItem.url` · `DownloadItem.error` 추가. 받기 팝업이 원본 주소를 받는다 (검색 결과 · 상세에서 `hit.url`).
- 끝난 곡이 생기면 `DownloadCompletionListener`가 커버 · 색 저장소를 다시 읽는다.
- 문구: `statusPaused` · `statusQueued` (ko · en).

## 바꾼 설정
- Android `MediaStoreChannel.kt`에 `saveAudio` 메서드 추가 (`ContentValues` · `Environment` import). Manifest · Gradle · pubspec 변경 없음 (`path_provider`는 이미 있다). 새 패키지 없음.

## 확인
- `flutter analyze` 경고 0, `dart format`, `flutter test` 통과 (대기열 단위 테스트 5건 추가: 완료 시 곡 등록, 실패 → 다시 받기, 엔진 실패, 받는 중 취소, 순차 받기).
- 기기 확인: 빌드(lite 디버그 APK)까지만 됐고, 기기 연결이 끊겨 실제 받기는 확인하지 못했다. 기기에서 받기 → 재생 확인 필요.

## 남은 일 · 질문
- 설정의 포맷(opus · mp3)과 음질(`Quality`)은 아직 받기에 반영되지 않는다. Android에는 변환기가 없어 원본(webm/opus, `.weba`)을 저장한다. mp3 변환이 필요하면 ffmpeg 계열 패키지를 도입할지 정해야 한다.
- 대기열이 메모리에만 있다 (앱을 끄면 받던 목록이 사라짐). 일시정지는 이어받기가 아니다.
- 곡 길이는 요청에 있는 값을 쓴다 (없으면 0). 파일에서 읽어 채우는 건 하지 않았다.
- Android 9 이하 저장은 `DATA` 칸으로 쓰도록 했지만 쓰기 권한 요청 흐름은 붙이지 않았고 확인하지 못했다.
