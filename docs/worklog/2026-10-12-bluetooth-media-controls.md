# 블루투스 · 출력 기기 연동 (미디어 버튼 · 세션 정리 · 연결/끊김 설정)

- 날짜: 2026-10-12
- 분류: 앱
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `feature/bluetooth-media-controls`
- 상세 기능: 알림 (재생 알림)

## 한 일
- 앱이 꺼지거나 프로세스가 죽은 뒤에도 블루투스 이어폰 · 차량의 재생/일시정지/다음/이전 버튼이 동작: `PlaybackStore`에 대기열 · 위치 · 반복 · 알림 내용을 저장하고, `MuloMediaButtonReceiver`(Media3 `MediaButtonReceiver` 상속)가 서비스를 깨우면 `PlaybackHub.init`이 되살려 이어 재생한다.
- 세션 정리 정책 ([D-103](../decisions.md)): 알림을 지웠거나 재생을 끝내면 세션을 release하고 버튼을 무시. 일시정지로 알림이 살아 있으면 버튼으로 이어 재생.
- 설정 '재생 설정'에 '기기가 끊기면 일시정지'(기본 켜짐) · '기기가 연결되면 이어 재생'(기본 꺼짐). 로직은 모두 Kotlin, Flutter는 값 저장과 전달만.
- 출력 기기가 바뀌면(`AudioDeviceCallback`) 앱에 `changed`를 보내 플레이어의 기기 이름을 갱신.

## 바꾼 설정
- AndroidManifest: 미디어 버튼 리시버를 `androidx.media3.session.MediaButtonReceiver` → `.MuloMediaButtonReceiver`로 교체. 권한 · 패키지 변화 없음.
- 채널: `music_app/playback`에 `setOutputBehavior`, `music_app/audio_output`에 네이티브→Dart `changed` 추가 ([native-playback.md](../native-playback.md)).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite` 성공. 블루투스 동작은 실기기 확인 필요.

## 남은 일 · 질문
- 연결 때 이어 재생은 프로세스가 살아 있을 때만 (죽은 뒤 기기 연결만으로 앱을 깨우지는 않는다).
- 앱 시작 때 마지막 대기열이 일시정지로 복원된다 (이전에는 프로세스가 죽으면 비어 있었다).
