# 영상 파일로 저장 (2026-11-10, 11-11 수정)

## 방식
- 받기 페이지 "저장" 구역에 **저장 유형(음원 / 영상)** 선택 (Android full 빌드만 보인다. 기본 음원). 영상을 고르면 형식(mp4 / webm)과 화질(360 · 480 · 720 · 1080p)을 고르고, 음원 전용 설정(형식 · 오디오 언어 · 재생목록 · 가사)은 숨긴다. 기본 mp4 · 1080p.
- 영상 받기는 음원과 **같은 대기열**로 처리한다 (`EngineDownloadQueueRepository`). 영상으로 저장하면 영상만 받아 끝나고(그동안 항목은 "처리 중") 보관함 곡은 만들지 않는다. 실패하면 항목이 실패하고 안내가 남으며 다시 받기로 이어진다.
- yt-dlp가 영상 + 소리를 받아 한 파일로 합친다 (APK의 ffmpeg 사용). mp4는 H.264 + AAC를 먼저 골라 다시 인코딩 없이 합치고, webm은 VP9 + Opus 원본을 쓴다.
- 완성된 파일은 MediaStore로 `Movies/Mulo`에 저장 (갤러리에 바로 보인다). 보관함 곡과는 따로다.
- 오래 걸리는 yt-dlp 실행이 검색 · 주소 읽기를 막지 않게 네이티브 `YtDlpChannel.run`에 `background`(별도 실행 줄)를 추가했다. 타임아웃 30분.

## 변경
- Dart: `VideoFormat` · `videoHeights`, `DownloadRequest.videoFormat` · `videoHeight`(대기열 저장에도 포함), `VideoSaveRepository`(domain) · `YtDlpVideoSaveRepository`(data), `IsVideoSaveAvailable`, 받기 페이지 스위치 · 선택, `AndroidYtDlp.run`에 `timeout` · `background`. 문구 3개(ARB + 생성 파일 손으로 맞춤).
- 네이티브: `MediaStoreChannel.saveAudio`에 `video` 플래그, `YtDlpChannel` 백그라운드 실행 줄.
- 패키지 · Manifest 변경 없음.

## 한계
- 영상 받는 동안 진행률은 없다 ("처리 중"으로만 보인다). 영상을 받는 중 일시정지 · 취소는 받던 yt-dlp를 바로 끊지 못하고 끝난 뒤 멈춘다.
- 데스크톱 · lite는 지원 안 함.

## 확인 필요
- PC: `dart format`, `flutter analyze`, `flutter test`, Android 빌드 (이 환경에서는 컴파일하지 못했다).
- 기기: 저장 유형을 영상으로 받기 → `Movies/Mulo`에 영상(보관함에는 곡이 생기지 않음), 음원으로 받기는 기존과 같음. 화질 · 형식별 재생과 소리, 저장 중 검색 · 미리 듣기 정상, 실패(비행기 모드) 안내.
