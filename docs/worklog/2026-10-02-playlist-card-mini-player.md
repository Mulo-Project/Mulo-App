# 플리 카드 대표곡 · 미니 플레이어 다듬기

- 날짜: 2026-10-02
- 분류: 앱 · 디자인
- 상태: 완료
- 브랜치 · 커밋: `ui/playlist-card-mini-player`
- 상세 기능: 공통 (UI 피드백)

## 한 일
- **재생목록 카드 대표곡**: 접으면 제목만 작게(낮은 한 줄, 높이 30), 누르면 영역이 커지며 제목이 커지고 아래에 가수 · 이미지 · 장르 · 재생 버튼이 붙는다.
- **미니 플레이어**: 재생 버튼만 원형으로 두고 다음 · 대기열은 배경 없는 작은 아이콘으로 줄였다.
- **현재 출력 기기**: 미니 플레이어 제목 아래에 아이콘 + 이름을 작게 보인다 (블루투스 · 유선 · USB · 기기 스피커). 곡이 바뀌거나 재생을 시작 · 멈출 때 다시 확인한다.
  - 클린 아키텍처로 `player` 기능에 `AudioOutput` 엔티티 · `AudioOutputRepository` · `GetAudioOutput` · `AudioOutputCubit`(앱 전체 bloc) 추가.
  - Android: `AudioOutputChannel`(`music_app/audio_output`, `AudioManager.getDevices`, 우선순위 블루투스 > 유선 > USB > 스피커). 다른 플랫폼은 알 수 없음(null)으로 두어 표시하지 않는다.

## 바꾼 설정
- Kotlin: `AudioOutputChannel` 추가, `MainActivity` 등록 · 해제. 권한 추가 없음(블루투스 기기 이름은 `productName`).
- 문구(ko · en): `outputSpeaker` · `outputWired` · `outputBluetooth` · `outputUsb` · `outputOther`.
- 새 패키지 · 에셋 없음.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (대표곡 테스트를 새 동작에 맞게 수정).
- 실기기에서 출력 기기 이름 표시는 확인하지 않았다.

## 남은 일 · 질문
- 재생 엔진이 붙으면 오디오 장치 변경 콜백으로 바꿔 즉시 반영할 수 있다 (지금은 곡 · 재생 상태가 바뀔 때만 확인).
