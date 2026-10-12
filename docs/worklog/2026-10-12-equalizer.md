# 이퀄라이저

- 날짜: 2026-10-12
- 분류: 앱
- 상태: 진행 중 (PR 확인 대기)
- 브랜치 · 커밋: `feature/equalizer`

## 한 일
- 설정 › 재생 설정에 '이퀄라이저' 줄 → 전용 화면(켜고 끄기 · 프리셋 9개 + 직접 조절 · 대역별 세로 슬라이더 · 저음 강화 · 처음으로). 기본 꺼짐, 값은 저장하고 앱을 켤 때 다시 반영.
- 소리 처리는 Kotlin `EqualizerEngine`이 ExoPlayer 오디오 세션에 `Equalizer` · `BassBoost`를 붙여서 한다. 통로는 `music_app/equalizer` (docs/equalizer.md, D-102).
- 디자인 시스템에 `AppSlider`(가로 · 세로) 추가. 카드 없이 기존 설정 줄 모양을 따랐다.
- Android가 아니면 이퀄라이저 줄을 숨긴다.

## 바꾼 설정
- `MainActivity`에 `EqualizerChannel` 등록, `PlaybackHub`가 오디오 세션 번호를 `EqualizerEngine`에 알림. 패키지 · 권한 변화 없음.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (이퀄라이저 단위 테스트 추가).
- 실제 소리 변화는 폰에서 확인 필요: 켜면 소리가 바뀌는지, 곡이 넘어가도 유지되는지, 앱을 껐다 켜도 값이 남는지.

## 남은 일 · 질문
- 일부 기기는 효과를 못 만들어 줄이 숨겨진다. 프리셋 곡선 값은 취향에 맞게 조정 가능.
