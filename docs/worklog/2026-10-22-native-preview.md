# 미리 듣기 소리를 네이티브로, Android 밖 재생 코드 삭제

- 날짜: 2026-10-22
- 분류: 앱
- 상태: 완료 (기기 확인 대기)
- 브랜치 · 커밋: `feature/native-preview`
- 상세 기능: 미리 듣기 (결정 D-118, D-093 후속)

## 한 일
- Kotlin `PreviewChannel` 추가(미리 듣기 전용 ExoPlayer, 진행 · 끝 · 실패를 Dart로 알림), `MuloEngine`에 등록.
- Dart `NativePreviewPlayer`로 `PreviewPlayer` 구현을 바꾸고 `JustAudioPreviewPlayer` 삭제.
- Android 밖 OS용 재생 코드 삭제: `JustAudioPlayerRepository`, `AudioEngineSource`, `initAudioBackend`, 관련 테스트.

## 바꾼 설정
- `pubspec.yaml`: `just_audio` · `just_audio_media_kit` · `media_kit_libs_windows_audio` · `media_kit_libs_linux` 제거.
- `android/app/build.gradle.kts`: `media3-exoplayer-hls` · `media3-exoplayer-dash` 1.7.1 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug` lite · full 둘 다 성공.
- 실제 기기에서 미리 듣기 소리 · 알림 조작은 아직 확인하지 못했다.

## 남은 일 · 질문
- 다운로드 쪽 데스크톱 코드(`YtDlpManager`, 폴더 불러오기 등)는 이번에 지우지 않았다.
