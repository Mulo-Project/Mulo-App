# 이퀄라이저 (D-102)

Flutter는 화면과 값 저장만 맡고, 소리 처리는 **네이티브 효과**가 한다. 지금은 Android만 있다 (Windows 등은 나중에 같은 약속으로).

## MethodChannel `music_app/equalizer`
| 메서드 | 인자 | 뜻 |
|---|---|---|
| `info` | – | 쓸 수 있으면 `bands`(대역별 중심 Hz, 낮은 쪽부터) `minDb` `maxDb`와 효과별 지원 여부 `bassBoost` `virtualizer` `reverb` `limiter`. 이퀄라이저를 못 만드는 기기는 null |
| `apply` | `enabled` `levels`(대역별 dB 목록) `bassBoost`(0~1) `virtualizer`(0~1) `reverb`(0=없음, 1~6 작은 방·중간 방·큰 방·중간 홀·큰 홀·플레이트) `limiter`(bool) | 값을 엔진에 반영한다. 꺼짐이면 모든 효과를 끈다 |

## Android 구현
- `EqualizerEngine`(Kotlin)이 ExoPlayer(`PlaybackHub.exo`)의 `audioSessionId`에 `Equalizer` · `BassBoost` · `Virtualizer`(입체 음향) ·  · `DynamicsProcessing` 리미터(소리 찢어짐 방지, Android 9+)를 붙인다. 리미터는 기본 켜짐(임계 -2dB). 세션 번호가 바뀌면(`onAudioSessionIdChanged`) 효과를 다시 만들고 마지막 값을 다시 넣는다.
- 대역 수 · dB 범위는 기기마다 달라서(보통 5대역, ±15dB) Dart가 `info`로 읽어 슬라이더를 그린다. 프리셋은 5점 곡선이고 기기 대역 수에 맞춰 펴 준다 (`EqualizerPreset.levelsFor`).
- 마지막 값은 `PlaybackHub`가 살아 있는 동안 네이티브가 쥐지만, 프로세스가 새로 뜨면 Dart(`EqualizerCubit`, 앱 시작 때 `load`)가 저장값을 다시 `apply`한다.

## 앱 쪽
- 저장: shared_preferences `player.equalizer`(JSON: enabled · preset · levels · bassBoost). 기본은 **꺼짐**, 평평한 값.
- 화면: 설정 › 재생 설정 › 이퀄라이저(`/settings/equalizer`). Android가 아니면 줄을 숨긴다. 슬라이더는 `AppSlider`(디자인 시스템).
- 켜고 끄기는 바로 저장한다. 프리셋 · 대역 · 효과는 손대는 즉시 소리에 반영하지만 **저장 버튼**을 눌러야 저장하고, 저장하지 않고 화면을 나가면 저장된 값으로 되돌린다 (`EqualizerCubit.discard`). 처음으로는 평평한 기본으로 되돌릴 뿐 저장은 따로 누른다.
- 플레이어 화면의 이퀄라이저 버튼(`EqualizerButton`)도 같은 화면(`/settings/equalizer`)으로 연다.

- 공간 울림은 기기 효과(`PresetReverb`)가 기기마다 거의 안 들려서 쓰지 않고, 재생 엔진 출력 앞단의 `ReverbProcessor`(Freeverb 방식, 16비트 PCM)로 직접 만든다 (`PlaybackHub`의 `DefaultAudioSink`에 연결). 프리셋 번호별 잔향 길이 · 고음 감쇠 · 섞는 양은 이 파일 상단 표.

## 프리셋 곡선
프리셋은 표준이 없어서 업계 관례(저음 강조 · 보컬 중고음 · 록의 V자 등)를 바탕으로 직접 정한 5점 dB 곡선이다 (낮은 소리 → 높은 소리, 기기 대역 수에 맞춰 편다).
기본 `0 0 0 0 0` · 저음 `6 4 1 0 0` · 고음 `0 0 1 4 6` · 보컬 `-2 0 3 3 -1` · 록 `4 1 -2 1 4` · 팝 `2 1 0 3 1` · 재즈 `2 2 1 0 -2` · 클래식 `0 0 0 2 3` · 힙합/EDM `6 3 -1 0 1`.
듣고 취향에 맞게 `EqualizerPreset._curve`를 고친다. 실시간 시각화(Visualizer, RECORD_AUDIO 권한 필요)와 시스템 전체 EQ(세션 0)는 넣지 않았다.

## 기기별 이퀄라이저 (D-104)
- 출력 기기(블루투스 이름 · 유선 · USB · 스피커)마다 전용 값을 둘 수 있다. 값은 **네이티브**(`EqualizerProfiles`, SharedPreferences `mulo_eq_profiles`)가 저장하고, 출력 기기가 바뀌면(`AudioDeviceCallback`) 그 기기의 값을 자동으로 엔진에 적용한다. 앱이 꺼져 재생 서비스만 살아 있어도 적용되고, 프로세스가 새로 뜰 때도 `PlaybackHub.init`이 지금 기기의 값을 적용한다.
- 기기 구분 열쇠는 `종류:이름`이라 이름이 같은 기기는 같은 값을 쓴다. 전용 값이 없는 기기는 앱의 기본 저장 값(`setBase`로 네이티브에 알려 둔다)을 쓴다.
- MethodChannel 추가: `device`(`{key,type,name,hasProfile}`), `profile`(지금 기기 전용 값 또는 null), `saveProfile`(맵, `apply` 인자 + `preset`), `deleteProfile`, `setBase`. 네이티브→Dart `deviceChanged`.
- 화면: 이퀄라이저 화면 맨 위 '이 기기 전용으로 저장' 스위치. 켜면 지금 값이 이 기기 전용이 되고 이후 저장은 이 기기 값으로 간다. 끄면 이 기기도 기본 값을 쓴다. 기기가 바뀌면 손보던 값이 없을 때 화면도 새 기기의 값으로 바뀐다.

## 내 프리셋과 기기 지정 (D-104)
- **내 프리셋**: 이퀄라이저 화면의 '내 프리셋'에서 `지금 값 저장`으로 이름을 붙여 만든다 (칩을 누르면 적용, 길게 누르면 삭제). 값은 네이티브(`EqualizerProfiles.presets`)에 저장한다.
- **기기별 지정**: 설정 › '기기별 이퀄라이저'에 연결된 적 있는 블루투스 · 이어폰 · USB 기기가 나오고(지금 기기가 맨 위), 기기를 눌러 내 프리셋을 고른다 ('기본 설정'을 고르면 전용 값을 없앰). 프리셋 값은 그 기기 프로필에 복사되고(`presetId`로 연결), 프리셋을 고치면 지정한 기기도 따라 바뀐다. 프리셋을 지우면 기기는 마지막 값을 그대로 쓴다.
- 기기 목록은 앱이 본 기기만 나온다 (연결될 때 `AudioDeviceCallback`으로 기억). 페어링만 되고 연결된 적 없는 기기는 `BLUETOOTH_CONNECT` 권한 없이 알 수 없어 나오지 않는다.
- MethodChannel 추가: `presets` `savePreset` `deletePreset` `devices` `assignPreset`.
- 기기 시트의 '이퀄라이저에서 직접 설정'은 연결돼 있지 않은 기기도 이퀄라이저 화면(`/settings/equalizer?device=<열쇠>`)으로 연다. 이때는 그 기기의 값을 고치고(없으면 기본 값에서 시작) 소리에는 반영하지 않으며, 저장하면 그 기기 전용 값이 된다 (네이티브 `profileFor` · `saveProfileFor`).
