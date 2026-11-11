# 영상 파일로 저장 (2026-11-10, 11-11 수정)

## 방식
- 받기 페이지 "저장" 구역에 **저장 유형(음원 / 영상)** 선택 (Android full 빌드만 보인다. 기본 음원). 영상을 고르면 형식(mp4 / webm)과 화질(360 · 480 · 720 · 1080p)을 고르고, 음원 전용 설정(오디오 형식 · 오디오 언어)만 숨긴다 (재생목록 · 가사는 음원과 같다). 기본 mp4 · 1080p.
- 영상 받기는 음원과 **같은 대기열**로 처리한다 (`EngineDownloadQueueRepository`). 영상으로 저장하면 영상만 받고(음원은 따로 받지 않는다) 끝나면 음원처럼 **보관함 곡으로 등록**한다: 커버(썸네일) · 색 · 재생목록은 앱이 따로 저장하므로 webm도 썸네일이 보인다. 곡의 폴더에는 저장한 위치를 적는다 (곡 상세에 폴더가 보인다). `Movies` · `Download`는 `LoadedFolderRepository.videoFolders`로 보관함 보임 기준(roots)에 더해 불러오는 폴더가 아니어도 숨겨지지 않는다. 원본 주소는 기억하지 않아 같은 곡을 음원으로도 받을 수 있다. 실패하면 항목이 실패하고 안내가 남으며 다시 받기로 이어진다.
- yt-dlp가 영상 + 소리를 받아 한 파일로 합친다 (APK의 ffmpeg 사용). mp4는 H.264 + AAC를 먼저 골라 다시 인코딩 없이 합치고, webm은 VP9 + Opus 원본을 쓴다.
- 완성된 파일은 MediaStore로 저장한다 (갤러리에 바로 보인다). 저장 위치는 받기 페이지 폴더 칸에서 `Movies/Mulo`(기본) · `Movies` · `Download` 중에서 고른다 (저장 유형을 바꾸면 폴더 칸도 바뀐다). `Download`는 MediaStore 다운로드 모음(Android 10+)으로 저장한다. 
- 받는 진행률: yt-dlp 진행 줄(`--newline`)을 네이티브가 읽어 `progress` 이벤트로 Dart에 보낸다. 영상 · 소리 두 파일이면 영상 0.9 · 소리 0.1로 합쳐 0~0.99로 보이고, 끝나면 합치기 · 저장이라 "처리 중"으로 보인다.
- 오래 걸리는 yt-dlp 실행이 검색 · 주소 읽기를 막지 않게 네이티브 `YtDlpChannel.run`에 `background`(별도 실행 줄)를 추가했다. 타임아웃 30분.

## 태그
- 저장 전에 ffmpeg로 제목 · 아티스트 · 앨범 · 장르를 파일에 쓴다 (영상 · 소리는 `-c copy`로 그대로). **mp4**는 커버도 첨부 그림으로 넣고(앱 커버 편집 값 + 앱 전용 `COVER_*` 칸 포함), **webm**은 그림 없이 글 태그만 쓴다 (첨부 그림을 못 넣는 형식이고, 글 태그는 VLC · mpv 같은 PC 플레이어가 읽는다). 태그를 못 써도 영상은 그대로 저장한다. 네이티브 `TranscoderChannel.tagVideo`.

- 가사: 음원처럼 앱(`lyrics/<id>.lrc`)에 저장하고, 파일 태그(`lyrics`: mp4 ©lyr · Matroska LYRICS)에도 같은 글을 넣는다.
- 곡 정보(제목 · 아티스트 · 앨범 · 장르 · 커버 · 색 · 가사)는 앱 DB가 원본이고, 파일에는 표준으로 담을 수 있는 만큼만 담는다 (webm은 커버 없음).

## 변경
- Dart: `VideoFormat` · `videoHeights`, `DownloadRequest.videoFormat` · `videoHeight`(대기열 저장에도 포함), `VideoSaveRepository`(domain) · `YtDlpVideoSaveRepository`(data), `IsVideoSaveAvailable`, 받기 페이지 스위치 · 선택, `AndroidYtDlp.run`에 `timeout` · `background`. 문구 3개(ARB + 생성 파일 손으로 맞춤).
- 네이티브: `MediaStoreChannel.saveAudio`에 `video` 플래그, `YtDlpChannel` 백그라운드 실행 줄.
- 패키지 · Manifest 변경 없음.

## 곡 상세 (영상)
- 형식 이름은 MP4 · WebM · MKV로 보이고, 해상도(가로 × 세로) 행이 더해진다. 샘플레이트는 소리 트랙에서 읽는다(영상은 첫 트랙이 영상이라 따로 돈다). 영상으로 저장한 곡은 원본 주소를 기록하지 않아 주소 줄이 없다.
- 곡 정보를 고치면 영상 파일 태그는 바꾸지 않고 앱 DB만 바뀐다 (후속).

## 한계
- 영상을 받는 중 일시정지 · 취소는 받던 yt-dlp를 바로 끊지 못하고 끝난 뒤 멈춘다.
- 데스크톱 · lite는 지원 안 함.

## 확인 필요
- PC: `dart format`, `flutter analyze`, `flutter test`, Android 빌드 (이 환경에서는 컴파일하지 못했다).
- 기기: 저장 유형을 영상으로 받기 → `Movies/Mulo`에 영상, 보관함에 곡(썸네일 포함), 음원으로 받기는 기존과 같음. 화질 · 형식별 재생과 소리, 저장 중 검색 · 미리 듣기 정상, 실패(비행기 모드) 안내.

## 상세 화면: 앱이 관리하는 재생 기록 (11-11)
- 음원 · 영상 상세 화면에 재생 횟수 · 들은 시간 · 마지막 재생 행 추가 (재생 기록이 없으면 횟수 0회만).
- `GetTrackPlayStats`(home 유스케이스) + `TrackPlayStats`, l10n `trackInfoPlayCount*` · `trackInfoListened` · `trackInfoLastPlayed`, 테스트 `test/track_play_stats_test.dart`.

## mp4 영상도 파일 태그가 원본 (11-11)
- 곡 정보를 고치면 mp4 영상은 파일 태그를 먼저 쓰고 DB를 바꾼다 (`TrackTagSource`가 `video/mp4`를 `embedVideo`로 쓴다. 가사만 쓰는 호출은 기존 태그를 지울 수 있어 영상은 건너뜀).
- 기기에서 찾은 mp4 영상은 파일 태그(제목 · 아티스트 · 앨범 · 장르)를 읽어 DB를 되살린다 (`FileTagSource`가 `Mp4Metadata`를 읽음). mp4에는 `COVER_*` 칸을 쓰지 않아 커버 편집 상태는 복원하지 않는다.
- webm은 해당 없음(앱 DB가 기준). 한계: 편집 시 mp4의 가사 태그가 비워질 수 있음(DB에는 남음).

## 태그 쓰기: 기존 태그 유지 (11-11)
- 전엔 ffmpeg `-map_metadata 1`로 넘긴 값만으로 태그를 새로 써서, 정보 편집이 가사 · 커버 칸을 지우고 가사 저장이 제목 등을 지울 수 있었다 (음원 · 영상 공통).
- 이제 기존 태그를 두고 넘어온 칸만 `-metadata`로 덮어쓴다 (빈 문자열은 그 칸을 지움, null은 건드리지 않음). 새 커버가 없으면 파일의 커버도 그대로 둔다. `TranscoderChannel.readFfmetadata`.
- 가사만 저장할 땐 제목 · 아티스트 · 앨범 · 장르를 null로 넘긴다. mp4 영상의 "가사만 저장 건너뜀"은 없앴다.
- 실기기 확인 필요 (mp3 · opus · mp4: 편집 후 가사 · 커버 유지, 가사 저장 후 제목 유지, 장르 비우면 지워짐).

## 영상으로 저장한 곡을 영상으로 재생 (11-11)
- 영상으로 저장한 곡이 소리만 나오던 문제: `Track.isVideo`가 id 접두사 · 확장자 · `hasVideo`(DB에 저장 안 됨)로만 판단해, 받은 영상(id `download:…`, content:// 주소)이 영상으로 인식되지 않았다.
- 영상 저장 곡의 id를 `download:video:<id>`로 하고 `isVideo`가 이 접두사를 영상으로 본다. 이미 저장해 둔 영상은 id가 달라 다시 저장해야 영상으로 재생된다.

## 영상 곡 표시를 DB에 저장 (11-11)
- id · 주소로 영상 여부를 추측하던 것을 없애고, 파일 형식(MIME)을 `tracks.mime` 열(스키마 13)에 저장한다. 영상으로 받아 저장하면 `video/mp4` · `video/webm`을 넣고, `Track.isVideo`는 `mime`이 `video/`로 시작하는지 본다 (기존 `device-video:` · 확장자 판단은 그대로). 상세 화면의 형식 이름도 파일을 읽기 전에 이 값으로 보인다.
- 마이그레이션 13: 열을 더하고, 주소가 `content://media/external/video/…`인 기존 곡은 `video/*`로 한 번 채운다. 다운로드 폴더에 저장한 예전 영상은 알 수 없어 다시 저장해야 한다.
- **`dart run build_runner build -d` 필요** (drift 생성 코드 `app_database.g.dart`를 이 환경에서 만들 수 없다).
- 진단 로그: 받기 등록(`MuloDownload register …`, flutter), 영상 해독(`video refresh/size/first frame`, `tracks video=… mime=…`, `adb logcat -s MuloPlayback`), 플레이어 화면(`MuloPlayer track=… isVideo=…`).

## 플레이어 테마별 영상 전체 보이기 (11-11)
- 사각: 영상 곡은 정사각 대신 영상 비율 그대로(`VideoSurfaceCubit`의 크기, 모르면 16:9). 꽉 찬 이미지 · 둥근 진행 표시: `BoxFit.contain`으로 영상 전체가 보이고 남는 곳은 커버가 비친다. `NativeVideoWithFullscreen` · `NativeVideoTapFullscreen`에 `fit`을 더했다.
- 영상 뒤에 깔리는 커버는 살짝 흐리게(blur 10, 투명도 .55) 하고 커버 색을 입힌 바탕(alpha .45) 위에 얹어 남는 자리가 영상과 자연스럽게 이어진다 (`PlayerCover`).
- 꽉 찬 이미지 테마: 영상 곡은 영상을 상단 버튼줄 밑 ~ 조작부 위 칸에 `contain`으로 딱 맞게 그리고(버튼줄과 겹치지 않음), 윗배경은 색을 입힌 흐린 커버(`PlayerCover.softBackdrop`)로 깐다.
- 사각 · 둥근 진행 표시 테마: 영상 곡도 음원처럼 정사각형 / 원 틀을 유지하고, 영상은 틀을 꽉 채운다(`PanZoomVideo`). 끌어서 가려진 부분을 보고, 두 손가락으로 확대(최대 4배) · 축소(영상 전체가 보이는 크기까지)하며, 두 번 누르면 틀 채우기로 돌아온다. 사각은 전체 화면 버튼, 원은 영상 한 번 누르기로 전체 화면. (앞서 만든 영상 비율 틀 · 영상 틀 진행 선은 이 방식으로 대체)
