# 영상 파일로 저장 (2026-11-10)

## 방식
- 받기 창에 "영상으로 저장" 버튼 (Android full 빌드만 보인다). 누르면 창을 닫고 뒤에서 받는다.
- yt-dlp가 영상 + 소리를 받아 mp4 한 파일로 합친다 (APK의 ffmpeg 사용, 최대 1080p). 720p 이상은 영상 · 소리가 따로 오므로 yt-dlp가 합친다. H.264 + AAC를 먼저 골라 다시 인코딩 없이 합친다.
- 완성된 mp4는 MediaStore로 `Movies/Mulo`에 저장 (기기 갤러리에 바로 보인다). 보관함 곡 · 대기열과는 따로다 (음원 보관함에 넣지 않는다).
- 오래 걸리는 yt-dlp 실행이 검색 · 주소 읽기를 막지 않게, 네이티브 `YtDlpChannel`의 `run`에 `background`(별도 실행 줄)를 추가했다. 타임아웃은 30분.

## 변경
- Dart: `VideoSaveRepository`(domain) · `YtDlpVideoSaveRepository`(data) · `SaveVideoFile` / `IsVideoSaveAvailable` 유스케이스, 받기 창 버튼, `AndroidYtDlp.run`에 `timeout` · `background`. 문구 4개(ARB + 생성 파일 손으로 맞춤).
- 네이티브: `MediaStoreChannel.saveAudio`에 `video` 플래그(영상 모음에 넣기), `YtDlpChannel` 백그라운드 실행 줄.
- 패키지 · Manifest 변경 없음.

## 한계
- 진행률 표시 없음 (시작 · 끝 스낵바만). 앱을 닫으면 받던 영상은 끊긴다. 대기열에 들어가지 않는다.
- 데스크톱 · lite는 지원 안 함.

## 확인 필요
- PC: `dart format`, `flutter analyze`, `flutter test`, Android 빌드 (이 환경에서는 컴파일하지 못했다).
- 기기: 영상 저장 → `Movies/Mulo`에 mp4가 생기고 소리 · 화질 정상 재생, 저장 중 검색 · 미리 듣기가 멈추지 않는지.
