# 네이티브 재생 약속 (플랫폼 중립)

OS에 묶인 것(재생 엔진 · 미디어 세션 · 알림 · 포그라운드 서비스)만 네이티브가 쥔다 (D-093).
보관함 · 재생목록 · 대기열의 규칙 · 상태 · 화면은 Dart(`NowPlayingCubit`)가 쥔다.
Android는 Kotlin(Media3), Windows는 나중에 C++로 **같은 약속**을 구현한다. 그 밖의 OS는 지금 just_audio.

Dart 쪽 도메인 인터페이스: `AudioPlayerRepository`(엔진), `MediaSession`(알림 · 세션).
통로: `lib/core/platform/native_playback_channel.dart`.

## MethodChannel `music_app/playback`
| 메서드 | 인자 | 뜻 |
|---|---|---|
| `load` | uri 문자열 (`content://` · `file://`) | 불러와 재생 준비가 되면 성공, 못 열면 오류. 재생은 시작하지 않는다 |
| `play` / `pause` | – | 끝까지 들은 곡이면 처음부터 |
| `seek` | 밀리초 | |
| `setSession` | 아래 맵 또는 null | null이면 알림을 치운다 (재생은 그대로) |

`setSession` 맵: `title artist album artUri durationMs positionMs playing hasPrevious hasNext favorite preview favoriteLabel unfavoriteLabel closeLabel`.
`preview: true`면 소리는 Dart 쪽 미리 듣기 플레이어가 내므로 네이티브는 `playing` · `positionMs`를 그대로 보여 주고 조작은 모두 `command`로 돌려보낸다.
메인(`preview: false`)은 엔진 상태가 진실이라 `playing` · `positionMs`는 쓰지 않는다.

## EventChannel `music_app/playback/events`
| `type` | 필드 | 언제 |
|---|---|---|
| `playing` | `value` bool | 엔진이 소리를 내려는 상태가 바뀔 때. **다른 앱에 오디오 포커스를 뺏겨 멈추거나 돌려받아 재개할 때도 보낸다** |
| `position` | `ms` | 재생 중 약 250ms마다, 이동 직후 |
| `completed` | – | 곡 끝 |
| `command` | `name` `positionMs?` | 알림 · 이어폰에서 온 조작: `next previous favorite stop`, 미리 듣기 중엔 `play pause seek`도 |

## 수명 규칙
- 서비스 · 세션은 네이티브가 쥔다. 닫기(X)는 재생을 멈추고 알림(포그라운드 서비스)을 치우되 세션은 남기며 다시 재생하면 알림이 돌아온다. 알림 밀어서 지우기 · 앱 종료는 **재생만 멈추고** 서비스 · 세션은 남긴다.
- 재생 · 일시정지 · 이동은 Dart 없이도 네이티브가 직접 처리한다 (화면이 사라져도 알림 버튼이 먹는다). 이전 · 다음 · 좋아요는 대기열이 Dart에 있어 `command`로 넘긴다.
- 오디오 포커스: 영상 등으로 빼앗기면 엔진이 멈추고 `playing:false`가 온다. `NowPlayingCubit`이 `isPlaying`을 맞춰 재생 버튼이 다시 먹는다.
