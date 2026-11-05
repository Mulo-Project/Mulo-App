# 동영상 재생 · 미니 플레이어 영상 표시 (2026-11-05)

## 방식
- **소리는 네이티브, 화면은 Dart**: 네이티브(ExoPlayer)는 영상 트랙을 끄고(`TRACK_TYPE_VIDEO` 비활성) 소리만 낸다. Dart(`video_player`)가 같은 영상을 소리 없이(`volume 0`, `mixWithOthers`로 오디오 포커스도 안 가져감) 틀고, 네이티브가 알려 주는 재생 위치 · 재생 상태를 따라간다. 0.6초 넘게 어긋나면 위치를 다시 맞춘다 (`MutedVideo`).
- 앱 화면이 사라지면 영상도 사라지고 소리만 이어진다.
- 다운로드는 그대로 오디오(mp3 · opus)만 받는다.

## 변경
- 폴더 불러오기: `MediaStoreChannel.queryVideo`(MediaStore.Video), Dart는 영상 권한(`READ_MEDIA_VIDEO`, Android 13+)을 따로 물어 거절돼도 음악 불러오기는 그대로 된다. 영상 곡 id는 `device-video:<id>`, `Track.isVideo`는 id 앞머리(또는 파일 확장자)로 가른다 (DB 스키마 변경 없음).
- 보관함 영상 곡: 미니 플레이어(`MiniPlayerBar.video`, 가로 78×44)와 플레이어 화면 커버(`PlayerCover.video`)가 커버 대신 영상을 보여 준다. 영상이 열리기 전에는 커버가 보인다.
- YouTube 미리 듣기: `DownloaderEngine.resolveVideoStream`(yt-dlp, 소리 없는 360p 이하 영상 하나) → `PreviewVideoCubit` → 미리 듣기 미니 플레이어에 영상 표시. 못 읽으면 커버를 그대로 둔다.
- 패키지 추가: `video_player` (pubspec). `flutter pub get` 필요.

## 한계
- 이미 받은 opus 곡은 원본 영상 주소를 저장하지 않아서 영상이 나오지 않는다 (후속: 받을 때 원본 주소를 태그에 남기기).
- 데스크톱 폴더 스캔은 아직 영상 확장자를 읽지 않는다 (Android 우선).

## 확인 필요
- PC: `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, Android 빌드.
- 기기: 영상 파일 폴더 불러오기 → 재생 시 미니 플레이어/플레이어 영상, 일시정지 · 탐색 · 다음 곡 동기, 앱을 뒤로 보냈다 돌아올 때 영상 복귀, YouTube 미리 듣기 영상.
