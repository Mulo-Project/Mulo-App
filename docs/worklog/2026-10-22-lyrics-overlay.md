# 떠 있는 가사 (오버레이)

- 날짜: 2026-10-22
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/lyrics-overlay`
- 상세 기능: 가사 (앱 밖에서 보는 가사)

## 한 일
- 앱을 벗어나 다른 앱을 쓰는 동안 화면 위에 지금 부르는 줄을 띄운다 (Android, 싱크 가사가 있는 곡). 끌어서 위아래로 옮길 수 있고 자리를 기억한다.
- 켜고 끄기: 플레이어 더보기 메뉴 "떠 있는 가사 켜기/끄기"에서만 (설정 화면에는 두지 않는다). 한 번 켜면 설정이 저장돼 이후 곡에서도 계속 뜬다. 켤 때 "다른 앱 위에 표시" 권한이 없으면 시스템 설정을 연다.
- 네이티브(`LyricsOverlay.kt`)가 시간 붙은 가사를 한 번 받아 두고 ExoPlayer 위치를 직접 읽는다: 앱(Dart)이 종료돼도 줄이 넘어간다.
- 최적화: 다음 줄 시간에 맞춘 타이머 하나만 예약하고 줄이 바뀔 때만 글자를 바꾼다 (주기 틱 없음). 멈춤 · 앱 화면이 보임 · 다른 곡 · 가사 없음이면 타이머 없이 창을 뗀다. 재생 속도도 반영.
- 곡 정보 숨기기가 켜져 있으면 가사를 보내지 않는다.
- Dart: `LyricsOverlay` 인터페이스 + 유스케이스, `LyricsOverlayCubit`, `LyricsOverlayBridge`(앱 셸), `LyricsSettings.overlay`.

## 바꾼 설정
- AndroidManifest: `SYSTEM_ALERT_WINDOW` 권한 추가.
- Kotlin: `LyricsOverlay.kt` · `LyricsOverlayChannel.kt` 추가, `MuloEngine` 채널 등록, `PlaybackHub` 플레이어 이벤트 · `MainActivity` 화면 보임 여부 연결.
- ARB 문구 추가. pubspec · Gradle 변경 없음.

## 확인
`flutter analyze` 경고 0, `flutter test` 통과. Android 실기기 확인은 아직 못 함 (오버레이 권한, 줄 넘김 타이밍, 끌어서 옮기기).

## 남은 일 · 질문
- 일시정지 중에는 마지막 줄을 그대로 둔다. 앱 화면이 보이면 숨긴다.
