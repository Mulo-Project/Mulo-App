# Android 재생 · 알림 네이티브 이전

- 날짜: 2026-10-08
- 분류: 앱 · 설정
- 상태: 진행 중 (확인 대기)
- 브랜치 · 커밋: `feature/native-media-playback`
- 상세 기능: 알림 (재생 알림)

## 한 일
- [D-093](../decisions.md), [native-playback.md](../native-playback.md): 재생 엔진 · 미디어 세션 · 알림 · 서비스를 Kotlin(Media3)으로. Dart는 도메인 인터페이스 뒤에서 명령만 보낸다.
- 버그 4개: 오디오 포커스 뺏김 때 재생 상태 불일치(엔진 재생 신호 추가), 미리 듣기 포커스(일시정지로 두기), 서비스 수명(닫기 · 밀어서 지우기는 재생만 멈춤), 미리 듣기를 재생 알림에 합침(유지).
- 새 Kotlin: `PlaybackHub` · `SessionPlayer` · `MuloPlaybackService` · `PlaybackChannel`. 지운 것: `MuloAudioHandler` · `AudioServiceMediaSession`.

## 바꾼 설정
- pubspec: `audio_service` 제거.
- Gradle: `androidx.media3:media3-exoplayer` · `media3-session` 1.7.1 추가.
- AndroidManifest: audio_service 서비스 · 리시버 → `MuloPlaybackService` · Media3 `MediaButtonReceiver`.
- `MainActivity`: `AudioServiceFragmentActivity` → `FlutterFragmentActivity`, `PlaybackChannel` 연결.
- 새 문자열 리소스 `notif_channel_playback`(ko · en).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과(포커스 뺏김 테스트 3개 추가), `flutter build apk --debug --flavor lite` 성공, 기기에 설치해 앱 실행까지 확인.
- 기기 확인 필요: 재생 · 일시정지 · 이전 · 다음 · 좋아요 · 닫기, 다른 앱 영상 재생 시 멈춤과 재생 버튼 복귀, 미리 듣기 알림, 밀어서 지운 뒤 재생, 앱 종료 시 동작.

## 남은 일 · 질문
- 미리 듣기 소리(just_audio)의 네이티브 이전.
- 닫기(X)가 일시정지 알림으로 남는 동작 확인.
