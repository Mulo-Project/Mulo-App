# 셔플 · 반복을 네이티브가 쥐기 (재생 상태 일원화 1단계)

- 날짜: 2026-11-04
- 분류: 앱
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `refactor/native-owns-queue-order`
- 상세 기능: 재생 상태 네이티브 일원화 계획 (D-152)

## 한 일
- `setShuffle` · `setRepeat` 명령, `queue` 이벤트, 스냅샷 `shuffleNew` 추가 (네이티브 `PlaybackHub` · `PlaybackChannel`, Dart 채널 · 저장소 · 유스케이스).
- 알림 셔플 버튼과 앱 화면이 같은 네이티브 `toggleShuffle`을 쓴다. 한 바퀴 뒤 재셔플도 앱 유무와 관계없이 네이티브가 하고 앱은 `queue` 이벤트를 비춘다.
- `NowPlayingCubit`: 엔진이 있으면 Dart 셔플 · 재셔플 · `extras` 작성을 쓰지 않는다 (엔진이 없을 때만 예전 Dart 셔플).
- debug 전용 `MuloLog`(`MuloNative` `MuloPlayback`): 채널 비동기 실패, 재생 채널 호출 예외, ExoPlayer 오류, 셔플 · 대기열 명령.
- 테스트: 가짜 엔진이 셔플(지금 곡 맨 앞 + 나머지 뒤집기) · 반복 · `queue` 이벤트를 흉내 내도록 고치고 `audio_playback_test.dart`를 새 약속에 맞췄다.

## 바꾼 설정
- 없음 (Gradle · Manifest · pubspec 변경 없음).

## 확인
- 클라우드 환경이라 빌드 · `flutter analyze` · `flutter test`를 돌리지 못했다. **PC에서 `flutter analyze` → `flutter test` → `flutter build apk --debug --flavor full` 필요.**
- 기기: 셔플 켜기/끄기(원래 순서 복원), 알림 셔플 버튼(앱 켜짐/꺼짐), 한 바퀴 뒤 재셔플, 셔플 중 다음에 재생 · 삭제, 셔플 켠 채 새 곡 목록 재생 · "셔플 재생", 반복 변경, 앱 종료 후 복원.

## 남은 일 · 질문
- 2단계(대기열 편집 명령), 3단계(Cubit 읽기 전용)는 1단계 기기 확인 뒤.
