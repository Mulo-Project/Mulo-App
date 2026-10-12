# 이퀄라이저 (D-102)

Flutter는 화면과 값 저장만 맡고, 소리 처리는 **네이티브 효과**가 한다. 지금은 Android만 있다 (Windows 등은 나중에 같은 약속으로).

## MethodChannel `music_app/equalizer`
| 메서드 | 인자 | 뜻 |
|---|---|---|
| `info` | – | 쓸 수 있으면 `bands`(대역별 중심 Hz, 낮은 쪽부터) `minDb` `maxDb` `bassBoost`(저음 강화 지원 여부). 효과를 못 만드는 기기는 null |
| `apply` | `enabled` `levels`(대역별 dB 목록) `bassBoost`(0~1) | 값을 엔진에 반영한다. 꺼짐이면 효과를 끈다 |

## Android 구현
- `EqualizerEngine`(Kotlin)이 ExoPlayer(`PlaybackHub.exo`)의 `audioSessionId`에 `Equalizer` · `BassBoost`를 붙인다. 세션 번호가 바뀌면(`onAudioSessionIdChanged`) 효과를 다시 만들고 마지막 값을 다시 넣는다.
- 대역 수 · dB 범위는 기기마다 달라서(보통 5대역, ±15dB) Dart가 `info`로 읽어 슬라이더를 그린다. 프리셋은 5점 곡선이고 기기 대역 수에 맞춰 펴 준다 (`EqualizerPreset.levelsFor`).
- 마지막 값은 `PlaybackHub`가 살아 있는 동안 네이티브가 쥐지만, 프로세스가 새로 뜨면 Dart(`EqualizerCubit`, 앱 시작 때 `load`)가 저장값을 다시 `apply`한다.

## 앱 쪽
- 저장: shared_preferences `player.equalizer`(JSON: enabled · preset · levels · bassBoost). 기본은 **꺼짐**, 평평한 값.
- 화면: 설정 › 재생 설정 › 이퀄라이저(`/settings/equalizer`). Android가 아니면 줄을 숨긴다. 슬라이더는 `AppSlider`(디자인 시스템).
- 슬라이더를 끄는 동안은 엔진에만 반영하고, 손을 뗄 때 저장한다.
