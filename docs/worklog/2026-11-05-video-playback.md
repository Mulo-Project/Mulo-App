# 동영상 재생 · 미니 플레이어 영상 표시 (2026-11-05)

## 방식
- **소리는 네이티브, 화면은 Dart**: 네이티브(ExoPlayer)는 영상 트랙을 끄고(`TRACK_TYPE_VIDEO` 비활성) 소리만 낸다. Dart(`video_player`)가 같은 영상을 소리 없이(`volume 0`, `mixWithOthers`로 오디오 포커스도 안 가져감) 틀고, 네이티브가 알려 주는 재생 위치 · 재생 상태를 따라간다. 0.6초 넘게 어긋나면 위치를 다시 맞춘다 (`MutedVideo`).
- 앱 화면이 사라지면 영상도 사라지고 소리만 이어진다.
- 다운로드는 그대로 오디오(mp3 · opus)만 받는다.

## 변경
- 폴더 불러오기: `MediaStoreChannel.queryVideo`(MediaStore.Video), Dart는 영상 권한(`READ_MEDIA_VIDEO`, Android 13+)을 따로 물어 거절돼도 음악 불러오기는 그대로 된다. 영상 곡 id는 `device-video:<id>`, `Track.isVideo`는 id 앞머리(또는 파일 확장자)로 가른다 (DB 스키마 변경 없음).
- 보관함 영상 곡: 미니 플레이어(`MiniPlayerBar.video`, 가로 78×44)와 플레이어 화면 커버(`PlayerCover.video`)가 커버 대신 영상을 보여 준다. 영상이 열리기 전에는 커버가 보인다.
- 영상 썸네일: 영상 파일은 내장 커버가 없으니 `embeddedPicture`가 영상 길이 10%(최대 10초) 지점 장면을 JPEG(긴 변 512px)로 돌려준다. 기존 `FillEmbeddedCovers`가 불러오기 때 이 장면을 곡 커버로 붙이므로 곡 목록 아이템에도 같은 커버가 나온다.
- 영상 상세 화면: 이 곡을 미리 듣는 동안 썸네일 자리(재생 버튼 대신)에 소리 없는 영상을 보여 주고, 화면을 나가면 미니 플레이어의 영상으로 이어진다. 영상 주소는 `CachedDownloaderEngine`에서 캐시해 두 화면이 다시 읽지 않는다.
- 썸네일의 재생 버튼(Android 유튜브 영상): 미리 듣기(소리 + 영상)로 그 자리에서 튼다. 시작하지 못하면 기존 앱 안 플레이어(웹뷰) → 유튜브 열기 순으로 넘어간다. 재생 중 영상을 누르면 일시정지 · 이어 재생. `togglePreview`는 성공 여부(bool)를 돌려준다 (`announceFailure`로 안내 생략 가능).
- 같이 시작: 미리 듣기가 막 시작되면(앞 2초 안, 곡마다 한 번) 영상 화면이 생길 때 소리를 잠시 멈추고(`PreviewCubit.holdForVideo`), 영상이 실제로 움직이기 시작하면(`MutedVideo.onStarted`) 소리를 이어서 낸다. 영상 주소를 못 읽거나 10초가 지나면 소리만 이어서 낸다. 위치를 다시 맞출 때는 버퍼링 중이면 건너뛰고 2초 간격을 둔다.
- YouTube 미리 듣기: `DownloaderEngine.resolveVideoStream`(yt-dlp, 소리 없는 360p 이하 영상 하나) → `PreviewVideoCubit` → 미리 듣기 미니 플레이어에 영상 표시. 못 읽으면 커버를 그대로 둔다.
- 패키지 추가: `video_player` (pubspec). `flutter pub get` 필요.

## 한계
- 이미 받은 opus 곡은 원본 영상 주소를 저장하지 않아서 영상이 나오지 않는다 (후속: 받을 때 원본 주소를 태그에 남기기).
- 데스크톱 폴더 스캔은 아직 영상 확장자를 읽지 않는다 (Android 우선).

## 확인 필요
- PC: `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, Android 빌드.
- 기기: 영상 파일 폴더 불러오기 → 재생 시 미니 플레이어/플레이어 영상, 일시정지 · 탐색 · 다음 곡 동기, 앱을 뒤로 보냈다 돌아올 때 영상 복귀, YouTube 미리 듣기 영상.
