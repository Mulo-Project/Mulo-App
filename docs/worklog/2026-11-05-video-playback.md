# 동영상 재생 · 미니 플레이어 영상 표시 (2026-11-05)

## 방식 (D-155)
- **소리와 영상은 네이티브가 한 시계로, 앱은 화면(텍스처)만 그린다.** 네이티브 `VideoSurfaceHub`가 Flutter 텍스처(`SurfaceProducer`) 하나를 쥐고, 미니 플레이어 · 상세 화면 · 플레이어가 같은 텍스처를 `NativeVideo` 위젯으로 나눠 그린다 (화면을 옮겨도 이어서 보인다).
- 영상 해독은 앱 화면이 붙어 있을 때만 켠다 (`VideoSurfaceCubit` → `attach`/`detach`, 모두 사라지고 3초 뒤 뗀다). 앱이 꺼지면 소리만 이어진다.
- 첫 화면이 그려지기 전(`ready` 이벤트)에는 뒤의 커버가 보이고, 그려지면 부드럽게 바뀐다.
- 다운로드는 그대로 오디오(mp3 · opus)만 받는다.

## 변경
- 네이티브: `VideoSurfaceHub` · `VideoChannel`(`music_app/video`: `attach` · `detach`, 이벤트 `size` · `ready`), `PlaybackHub`가 메인 플레이어를 허브에 등록 (영상 파일은 같은 플레이어가 영상도 해독), `PreviewChannel.playVideo`.
- YouTube 미리 듣기: 영상 전용 플레이어(소리 없음)가 소리 플레이어에 맞춰 돈다. 시작은 소리보다 1.5초 앞에서 멈춘 채 받아 두었다가 소리가 닿는 순간 튼다. 이후에는 되감지 않고 재생 속도 0.94~1.06배로 따라잡고, 2.5초 넘게 어긋날 때만 되감는다. 소리를 영상 때문에 늦추지 않는다.
- Dart: `VideoSurface`(domain) · `NativeVideoSurface`(data) · `VideoSurfaceCubit` · `NativeVideo`. `PreviewVideoCubit`은 영상 주소를 읽어 `PreviewPlayer.playVideo`로 네이티브에 넘긴다. 영상 주소는 `PreviewCubit`이 소리 주소와 함께 미리 읽어 둔다(엔진 캐시 공유).
- 폴더 불러오기: `MediaStoreChannel.queryVideo`(MediaStore.Video), 영상 권한(`READ_MEDIA_VIDEO`, Android 13+)은 따로 묻고 거절돼도 음악 불러오기는 그대로 된다. 영상 곡 id는 `device-video:<id>`, `Track.isVideo`로 구분 (DB 스키마 변경 없음).
- 영상 썸네일: `embeddedPicture`가 영상 길이 10%(최대 10초) 지점 장면을 JPEG로 돌려주고, 기존 `FillEmbeddedCovers`가 곡 커버로 붙인다.
- 상세 화면: 썸네일의 재생 버튼(Android 유튜브 영상)이 미리 듣기(소리 + 영상)로 그 자리에서 튼다. 실패하면 웹뷰 → 유튜브 열기. 재생 중 영상을 누르면 재생 · 일시정지 버튼이 2초간 뜬다 (멈춘 동안은 계속 보인다).
- 패키지: 추가한 것 없음 (Dart `video_player`는 쓰지 않는다). Manifest: `READ_MEDIA_VIDEO`.

## 한계
- 이미 받은 opus 곡은 원본 영상 주소가 없어 영상이 나오지 않는다 (후속: 받을 때 원본 주소를 태그에 남기기).
- 데스크톱 폴더 스캔은 아직 영상 확장자를 읽지 않는다 (Android 우선).
- 기기가 못 여는 코덱이면 화면은 커버로 남고 소리는 그대로 난다.

## 확인 필요
- PC: `dart format`, `flutter analyze`, `flutter test`, Android 빌드 (Flutter `SurfaceProducer` API · Media3 호출은 이 환경에서 컴파일하지 못했다).
- 기기: 영상 파일 폴더 불러오기 → 재생 시 미니 플레이어/플레이어 영상, 일시정지 · 탐색 · 다음 곡 동기, 앱을 뒤로 보냈다 돌아올 때 영상 복귀, YouTube 미리 듣기 영상(처음 합류 · 끊김 · 미니 플레이어 ↔ 상세 이동), 영상 썸네일 커버.
