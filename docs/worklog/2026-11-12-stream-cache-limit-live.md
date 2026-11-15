# 임시 저장 한도를 바꿔도 듣던 소리가 끊기지 않게 (2026-11-12)

## 문제
설정에서 임시 저장(스트림 캐시) 한도를 바꾸면 듣던 미리 듣기 소리가 끊기고 다시 들어도 재생되지 않았다.

## 원인
`StreamCache.setLimit`이 한도를 저장한 뒤 `close()`로 `SimpleCache`를 `release()`했다. 듣는 중인 플레이어의 데이터 소스는 이미 그 저장소를 쥐고 있어서, 닫힌 저장소를 읽다가 실패했고 (같은 데이터 소스 팩토리를 다시 쓰는 "다시 듣기"도 계속 실패) 앱을 다시 켜야 풀렸다. 기본 `LeastRecentlyUsedCacheEvictor`는 한도를 바꿀 수 없어서 저장소를 다시 열 수밖에 없는 구조였다.

## 변경
- `AdjustableLruEvictor`(기본 LRU 정리기와 같은 동작 + 한도 변경 가능)로 바꿔, `setLimit`이 저장소를 닫지 않고 새 한도를 바로 적용한다 (줄이면 오래 안 쓴 것부터 바로 정리).
- `clear`(지금 비우기)도 저장소를 닫지 않고 안의 항목만 지운다.
- 코드: `android/app/src/main/kotlin/com/mulo/app/StreamCache.kt`. 패키지 · Manifest 변경 없음.

## 확인 필요
이 환경에서는 Kotlin 컴파일 · 실행을 못 했다. 기기에서: 미리 듣기 중에 한도를 올리기 / 줄이기 / 지금 비우기를 해도 소리가 이어지는지, 한도를 줄였을 때 `사용 중` 용량이 바로 줄어드는지.

## 추가: 알림 재생 버튼 · 알림으로 앱 열기 (같은 PR)
- 미리 듣기 알림의 재생/일시정지: 예전에는 앱(Dart)을 한 번 거쳐야 동작해, 앱의 미리 듣기 상태(paused)가 실제와 어긋나면
  (예: 포커스 · 기기 이벤트로 네이티브만 멈춘 경우) 알림 버튼을 눌러도 무시됐다. 이제 `SessionPlayer`가 `PlaybackHub.previewControl`로
  소리를 직접 켜고 끄고, 앱에는 명령을 그대로 알려 `syncWithPlayer()`로 실제 상태에 맞춘다. 블루투스 `play`는 상태와 무관하게 동작해 왔다.
- 알림을 눌러 앱을 열 때: 임시 저장한 음원(`saved:`)을 메인 재생으로 듣는 중이면 플레이어 화면 대신 그 영상의 상세 화면을 연다
  (`lib/app/app.dart` `_openPlayer`).
- 알림 버튼 점검: 이전/다음/좋아요/셔플/닫기는 네이티브가 직접 처리하는 경로를 읽어 확인했고 결함은 위 하나였다 (실기기 확인 필요).

## 추가: 미리 듣기 상태를 네이티브로 (1단계)
- 방향: Flutter는 UI, 재생과 그 상태는 네이티브. 미리 듣기는 소리만 네이티브였고 상태(멈춤 · 반복)는 Dart가 쥐어 알림 버튼이 Dart를 거쳤다.
- 알림의 재생 · 일시정지 · 닫기: `SessionPlayer` → `PlaybackHub.previewControl` / `previewStop` → `PreviewChannel`이 직접 처리.
- 한 곡 반복: `setRepeat`로 값만 알리고, 곡이 끝나면 네이티브가 처음부터 다시 튼다 (`STATE_ENDED`). 앱이 응답하지 않아도 돈다.
- 멈춤 상태: 네이티브 `onPlayWhenReadyChanged`가 `paused` 이벤트를 보내고, `PreviewCubit`은 그 값을 화면에 반영만 한다 (`WatchPreviewPaused`).
- 2단계(주소 읽기 · hit 소유 · 끊김 복구)는 Dart의 엔진 라우팅(저장한 곡 주소 조회 · 화질 설정 · yt-dlp 대체 경로)과 얽혀 있어 아직 Dart에 남는다.

## 추가: 실기기 확인에서 나온 수정
- 캐시 크기를 바꾸면 미리 듣기가 꺼지던 문제: `StreamCache.setLimit`은 고쳤지만 `PreviewChannel`의 `setCacheLimit`이 먼저 `stop()`을 불러 소리를 끄고 있었다. 그 `stop()`을 뺐다.
- 임시 저장 음원 알림의 셔플 버튼: 좋아요 자리의 빈 버튼이 `setEnabled(false)`라 알림이 그리지 않아 셔플이 왼쪽으로 밀렸다. 빈 버튼을 켜 두고(눌러도 아무 일 없음) 셔플이 늘 오른쪽에 오게 했다.
- 곡 전환: 플레이어 화면이 열린 채 곡이 임시 저장 음원으로 넘어가면 플레이어 화면을 닫고 그 곡의 저장 상세로 간다. 알림 · 미니 플레이어 · 곡 전환이 모두 `pushSavedQueueDetail` 하나로 연다.
- 저장 상세에서 재생: 그 곡이 이미 메인 대기열에 있으면 대기열을 바꾸지 않고 그 곡으로 건너뛴다 (기존에는 임시 저장 곡 전체로 대기열을 갈아치웠다).
- 앱 종료 때 알림이 꺼지는 문제: 코드만으로 원인을 못 찾아, 앱을 밀 때와 엔진을 정리할 때의 판단을 `MuloPlayback` 로그로 남기게 했다.

## 추가: 플레이어 화면 하나로 합치기
- 일반 곡 ↔ 임시 저장 곡 전환이 화면을 닫고 여는 방식이라 어긋났다. 이제 목적지는 플레이어 화면(`Routes.player`) 하나다.
  임시 저장 곡일 때만 같은 화면이 썸네일 자리에 다운로드 상세(`SavedQueueDetailScreen`)를 보여 주고, 아래 조작부(`PlayerControls`)는 같은 위젯이다.
- 미니 플레이어와 알림은 모두 `Routes.player`만 연다. 곡이 넘어가도 화면을 닫고 다시 여는 일이 없다 (이전에 넣은 곡 전환 따라가기 · `_openSavedDetailOf`는 걷어냈다).
- 화면을 닫고 다시 여는 로직은 없다. 저장 타일에서 연 상세(`saved-queue-detail`)는 타일을 둘러보는 화면이라 따로 두고, 재생 중 화면은 플레이어 화면 하나다.
- 화면이 들썩이지 않게: 저장 상세의 맨 위 줄을 플레이어 화면과 같은 모양(제목 "지금 재생 중" · 아래로 내리기 버튼)으로 맞추고, 받기 · 원본 열기 버튼은 아래 고정 영역이 아니라 목록 끝으로 올려 하단에는 공통 조작부만 남겼다.
- 임시 저장 곡: 플레이어 화면은 일반 곡과 같은 레이아웃이고, 썸네일 자리가 "다운로드 영역"이다. 누르면 하단 조작부 없이 다운로드 페이지(`MediaDetailScreen`) 자체로 이동한다 (영상 곡은 영상 제스처가 먼저라 누름이 없다).
- 저장 타일은 이전처럼 `saved-queue-detail`(조작부가 붙은 상세)를 연다. 곡이 일반 ↔ 임시로 넘어가는 전환은 플레이어 화면 안에서 끝나 화면을 닫고 여는 로직이 없다.
- 상세의 재생 · 받기 버튼은 아래에 고정(저장 상세에서는 공통 조작부 바로 위)하고, 글자가 숨겨지지 않게 "재생"으로 줄였다 (유튜브 · SoundCloud · 원본 모두).
- 정리: 다운로드 상세에 붙어 있던 재생 조작 위젯(`SavedQueueDetailScreen` · `SavedQueueControls` · `savedMode` · `fromSaved` · `_startSaved`)을 모두 지웠다. 저장 타일은 다운로드 페이지(`showMediaDetail`)를 열고, 전체 재생 · 셔플은 플레이어 화면(`Routes.player`)을 연다 (D-165).
- 저장 타일의 정보 부분을 누르면 재생 화면(`Routes.player`)이 열린다: 끝까지 받은 곡은 그 곡부터 목록 재생을 시작하고(이미 듣는 중이면 그대로), 아직 받는 중인 곡은 다운로드 페이지를 연다. 다운로드 페이지는 재생 화면의 썸네일에서 들어간다.
- 정정: 임시 저장 곡의 가운데는 썸네일이 아니라 다운로드 페이지 내용이다 (`SavedPlayer`가 `MediaDetailScreen(embedded: true)`를 끼운다). 오른쪽 위 확장 버튼(`saved-expand`)을 누르면 다운로드 페이지 자체로 이동한다. 커버 누름(`onCoverTap`)은 걷어냈다.
- 설정의 영상 화질 시트가 낮은 화면 · 큰 글자에서 넘치던 문제: 내용을 `SingleChildScrollView`로 감싸고 `isScrollControlled` · `useSafeArea`로 열도록 했다 (저장 화질 시트와 같은 방식).
- 가운데(다운로드 영역)의 썸네일은 눌림을 막지 않는다: 지금 메인 재생 중인 임시 저장 곡이라 영상 곡은 메인 영상(컨트롤 포함), 소리만 저장한 곡은 영상 재생 버튼이 그대로 동작한다. 미리 듣기 영역만 뺐다.
- 영상 저장(`saveVideo`)이 403(Forbidden)으로 실패하던 문제: 주소 읽기와 같이 기본 클라이언트로 실패하면 `android_vr`로 한 번 더 받는다 (`withFallback`). 테스트 `saveVideoRetriesWithAndroidVrOnForbidden` 추가.
- 테스트: 옛 저장 상세(`queue-bar-play`) · 문구("Watch on YouTube")를 기대하던 `saved_queue_test` · `saved_button_sync_test` · `youtube_embed_test`를 새 구조(재생 화면 + `saved-expand`)에 맞췄다.

## 영상 저장: 네이티브 주소로 먼저 받기 (yt-dlp 403 대응)
- yt-dlp 영상 저장이 받는 단계에서 403이 나 android_vr 재시도도 실패했다. 재생이 쓰는 `YoutubeResolver`가 읽은 주소(구간 확인 통과)를 같은 헤더로 4MB씩 받고, 영상+소리 두 파일이면 ffmpeg로 이어 붙이는 `NativeVideoSaver`를 추가했다 (mp4만, full 빌드만 합치기 가능).
- 이 방법을 쓸 수 없거나 실패하면 기존 yt-dlp(+android_vr)로 넘어간다. `MuloNative` 로그: `영상 저장 네이티브 …ms 완료` 또는 `실패, yt-dlp로: …`.
- 디버그 빌드에서는 영상 저장 실패 사유를 snackbar(DiagNotice)로 보인다.

## 내장 커버 읽기를 네이티브로 모음
- opus · ogg · webm 내장 커버를 Dart(`audio_metadata_reader` + `METADATA_BLOCK_PICTURE` 직접 풀기, 캐시 복사)로 읽던 경로를 없앴다. `MediaStoreChannel.embeddedPicture`가 `MediaMetadataRetriever` → (영상은 장면) → `TagReader.picture`(Media3가 형식별 그림 칸을 풀어 준다) 순으로 읽고, Dart `MediaStorePictureReader`는 바이트만 받는다. 데스크톱용 `FilePictureReader`와 `vorbis_picture_test.dart`를 지웠다 (Android만 다룬다).
