# 실제 재생 (just_audio)

- 날짜: 2026-10-04
- 분류: 앱
- 상태: 진행 중 (PR 리뷰 대기, 기기 소리 확인 필요)
- 브랜치 · 커밋: `feature/real-playback`
- 상세 기능: 재생 (플레이어)

## 한 일
- 재생 엔진 계층: `AudioPlayerRepository`(domain) + 유스케이스 6개 + `AudioPlayback` 묶음, `JustAudioPlayerRepository` · `AudioEngineSource`(data).
- `NowPlayingCubit`이 엔진을 부른다: 곡 선택 · 다음 · 이전 · 재생/일시정지 · 이동. 엔진의 재생 위치로 진행 막대가 실제로 움직이고, 곡 끝에서 다음 곡 · 반복 처리.
- Windows · Linux는 media_kit 백엔드 (`initAudioBackend`).
- 테스트: `FakeAudioPlayer`, `audio_playback_test.dart` 11개.

## 바꾼 설정
- pubspec: `just_audio`, `just_audio_media_kit`, `media_kit_libs_windows_audio`, `media_kit_libs_linux` 추가. `windows/flutter/generated_plugin*` 자동 갱신분 포함.
- 매니페스트 변경 없음. Notion 기술 스택(Flutter · Native) DB에 위 패키지 행 추가 필요.

## 확인
- `flutter analyze` 0, `flutter test` 통과, `flutter build apk --debug` 성공.
- Windows 빌드는 이 PC에 Visual Studio 도구가 없어 확인하지 못했다. 기기에서 실제 소리 확인은 사용자가 해 봐야 한다.

## 남은 일 · 질문
- 백그라운드 재생 · 알림 · 잠금화면 조작 (`audio_service`), 셔플 순서, 이퀄라이저.
- #42(가짜 데이터 제거)에서 갈라져 나왔다. #42가 먼저 합쳐져야 한다.
