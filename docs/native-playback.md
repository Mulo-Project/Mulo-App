# 네이티브 재생 약속 (플랫폼 중립)

OS에 묶인 것(재생 엔진 · 미디어 세션 · 알림 · 포그라운드 서비스)과 **곡 넘김**은 네이티브가 쥔다 (D-093 · D-094).
보관함 · 재생목록의 규칙과 **대기열의 규칙**(셔플 · 다음에 재생 · 순서 이동 · 삭제)은 Dart(`NowPlayingCubit`)가 쥔다.
Dart가 정한 순서의 목록을 **스냅샷**으로 보내면 네이티브가 그 순서대로 재생하고 곡을 넘긴다.
Android는 Kotlin(Media3), Windows는 나중에 C++로 **같은 약속**을 구현한다. 그 밖의 OS는 지금 just_audio 위에서
Dart 쪽 `JustAudioPlayerRepository`가 같은 약속(스냅샷 · 곡 넘김 이벤트)을 흉내 낸다.

Dart 쪽 도메인 인터페이스: `AudioPlayerRepository`(엔진 · 대기열), `MediaSession`(알림 · 세션).
통로: `lib/core/platform/native_playback_channel.dart`.

## MethodChannel `music_app/playback`
| 메서드 | 인자 | 뜻 |
|---|---|---|
| `setQueue` | 스냅샷 맵 (아래) | 대기열을 통째로 바꾼다. 현재 곡이 재생할 준비가 되면 성공, 못 열면 오류. 현재 곡이 같으면 **재생을 끊지 않고** 앞뒤 목록만 맞춘다 |
| `skipTo` | 번호 | 대기열은 그대로 두고 그 곡으로 처음부터 옮긴다 |
| `play` / `pause` | – | 끝까지 들은 곡이면 처음부터 |
| `seek` | 밀리초 | |
| `setQueueArt` | 맵 (곡 id → 커버 주소) | 대기열 곡별 커버. 지금 곡이 아닌 곡의 알림 커버로 쓴다 (앱이 꺼진 사이 곡이 넘어가도 커버가 나오게). 곡 정보 숨기기가 켜져 있으면 빈 맵 |
| `getState` | – | 지금 쥐고 있는 스냅샷 (+ `playing` · `positionMs`). 곡이 없으면 null. 앱을 다시 켰을 때 복원용 |
| `takeOpenPlayerRequest` | – | 알림을 눌러 앱이 **새로 켜졌는지** 한 번 알려 주고 비운다 |
| `setSession` | 아래 맵 또는 null | null이면 알림을 치운다 (재생은 그대로) |

`setQueue` 스냅샷 맵: `items`(`id uri title artist album durationMs`의 목록, **Dart가 정한 순서**) `index` `playing` `repeat`(`off` `all` `one`) `positionMs`(없으면 같은 곡을 계속 듣는 것으로 보고 위치를 그대로 둔다) `extras`.
- `extras`는 Dart만 해석하는 문자열(셔플 여부 · 섞기 전 순서). 네이티브는 그대로 보관했다가 `getState`로 돌려준다.
- 셔플은 쓰지 않는다: 이미 섞인 순서를 보낸다. 반복 모드만 네이티브가 안다 (`all`이면 끝에서 처음으로, `one`이면 한 곡 반복).

`setSession` 맵: `trackId title artist album artUri durationMs positionMs playing favorite preview favoriteLabel unfavoriteLabel closeLabel hideSongInfo hiddenTitle hiddenNote unknownArtist`.
`trackId`가 지금 재생 곡의 id와 같을 때만 이 맵의 내용(커버 · 좋아요 포함)을 알림에 쓴다. 앱이 꺼진 사이 곡이 넘어가면 맵은 옛 곡의 것이므로
네이티브가 대기열에 실린 곡 정보(`title artist album`)로 알림을 그리고(`hideSongInfo`면 숨김 글자), 좋아요 버튼은 숨긴다.
`preview: true`면 소리는 Dart 쪽 미리 듣기 플레이어가 내므로 네이티브는 `playing` · `positionMs`를 그대로 보여 주고 조작은 모두 `command`로 돌려보낸다.
메인(`preview: false`)은 엔진 상태가 진실이라 `playing` · `positionMs`는 쓰지 않는다.

## EventChannel `music_app/playback/events`
| `type` | 필드 | 언제 |
|---|---|---|
| `playing` | `value` bool | 엔진이 소리를 내려는 상태가 바뀔 때. **다른 앱에 오디오 포커스를 뺏겨 멈추거나 돌려받아 재개할 때도 보낸다** |
| `position` | `ms` | 재생 중 약 250ms마다, 이동 직후 |
| `track` | `index` `id` | 엔진이 곡을 넘겼을 때 (곡 끝 · 알림 · 이어폰의 이전/다음). 목록을 바꾸느라 생긴 전환은 보내지 않는다. Dart는 `index`만 따라가고, 앱이 시킨 이동의 알림은 무시한다 |
| `ended` | – | 반복 없이 대기열 끝까지 들었다 (열 수 없는 곡을 만나 더 갈 곳이 없을 때도) |
| `command` | `name` `positionMs?` | 알림 · 이어폰에서 온 조작: `favorite stop`, 미리 듣기 중엔 `play pause seek`도. 이전/다음은 네이티브가 직접 처리한다 |
| `openPlayer` | – | 앱이 떠 있는 중에 알림을 눌렀다 → 현재 곡의 플레이어 화면을 연다 |

## 수명 규칙
- 서비스 · 세션 · **대기열**은 네이티브가 쥔다. 닫기(X)는 재생을 멈추고 알림(포그라운드 서비스)을 치우되 세션은 남기며 다시 재생하면 알림이 돌아온다. 알림 밀어서 지우기는 **재생만 멈추고** 서비스 · 세션은 남긴다.
- 앱을 끄거나(최근 작업에서 밀기) 화면이 사라져도 **재생은 계속**되고 다음 곡으로 이어진다. 프로세스가 죽으면 대기열도 사라진다 (복원 대상 아님).
- 앱이 다시 켜지면 Dart가 `getState`로 대기열 · 현재 곡 · 위치 · 반복 · `extras`를 읽어 상태를 복원한다 (보관함에서 사라진 곡은 건너뛰고 네이티브 대기열도 맞춘다). 이때는 네이티브를 다시 움직이지 않는다.
- 재생 · 일시정지 · 이동 · 이전 · 다음은 Dart 없이도 네이티브가 직접 처리한다 (화면이 사라져도 알림 버튼이 먹는다). 이전은 3초 넘게 들었으면 처음으로, 아니면 이전 곡(첫 곡이면 마지막 곡), 다음은 마지막 곡이면 전체 반복일 때만 처음으로. 좋아요는 Dart에 `command`로 넘긴다.
- Dart 쪽 셔플 한 바퀴: 셔플 중 `track` 이벤트가 마지막 → 처음으로 감기면 Dart가 새 순서로 스냅샷을 다시 보낸다 (듣던 곡은 그대로). 앱이 꺼진 사이는 같은 순서로 반복한다.
- 알림을 눌러 앱이 **새로 켜졌을 때**는 복원 · 이동이 끝날 때까지 앱 쪽이 덮개(음표 아이콘)로 첫 화면을 가려서, 홈 → 플레이어로 차례로 넘어가는 것이 보이지 않게 한다.
- 알림을 누르면 PendingIntent(`com.mulo.app.OPEN_PLAYER`)로 앱을 연다. 앱이 떠 있으면 `openPlayer` 이벤트, 새로 켜졌으면 `takeOpenPlayerRequest`가 true를 준다. Dart는 대기열 복원을 끝낸 뒤 플레이어 화면(`/player`)을 연다.
- 오디오 포커스: 영상 등으로 빼앗기면 엔진이 멈추고 `playing:false`가 온다. `NowPlayingCubit`이 `isPlaying`을 맞춰 재생 버튼이 다시 먹는다.
