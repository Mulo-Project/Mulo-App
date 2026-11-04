# 네이티브 재생 약속 (플랫폼 중립)

OS에 묶인 것(재생 엔진 · 미디어 세션 · 알림 · 포그라운드 서비스)과 **곡 넘김**은 네이티브가 쥔다 (D-093 · D-094).
보관함 · 재생목록의 규칙과 대기열 **편집**(다음에 재생 · 순서 이동 · 삭제)은 아직 Dart(`NowPlayingCubit`)가 계산한다 (D-152, 2단계에서 네이티브로).
**셔플 · 반복은 네이티브가 쥔다**: Dart는 `setShuffle` · `setRepeat` 명령만 보내고, 네이티브가 알려 주는 `queue` 이벤트의 순서를 비춘다.
Dart가 정한 순서의 목록을 **스냅샷**으로 보내면 네이티브가 그 순서대로 재생하고 곡을 넘긴다.
Android는 Kotlin(Media3), Windows는 나중에 C++로 **같은 약속**을 구현한다. 그 밖의 OS는 지금 just_audio 위에서
Dart 쪽 `JustAudioPlayerRepository`가 같은 약속(스냅샷 · 곡 넘김 이벤트)을 흉내 낸다.

Dart 쪽 도메인 인터페이스: `AudioPlayerRepository`(엔진 · 대기열), `MediaSession`(알림 · 세션).
통로: `lib/core/platform/native_playback_channel.dart`.

## MethodChannel `music_app/playback`
| 메서드 | 인자 | 뜻 |
|---|---|---|
| `setQueue` | 스냅샷 맵 (아래) | 대기열을 통째로 바꾼다. 현재 곡이 재생할 준비가 되면 성공, 못 열면 오류. 현재 곡이 같으면 **재생을 끊지 않고** 앞뒤 목록만 맞춘다 |
| `setShuffle` | bool | 셔플을 켜고 끈다. 켜면 지금 곡을 맨 앞에 두고 나머지를 섞으며 섞기 전 순서를 `extras.original`에 적고, 끄면 그 순서로 되돌린다. 듣던 곡은 끊기지 않는다. 바뀐 순서는 `queue` 이벤트로 온다 |
| `setRepeat` | `off` `all` `one` | 반복 모드. `queue` 이벤트로 확인해 준다 |
| `skipTo` | 번호 | 대기열은 그대로 두고 그 곡으로 처음부터 옮긴다 |
| `play` / `pause` | – | 끝까지 들은 곡이면 처음부터 |
| `seek` | 밀리초 | |
| `setQueueArt` | 맵 (곡 id → 커버 주소) | 대기열 곡별 커버. 지금 곡이 아닌 곡의 알림 커버로 쓴다 (앱이 꺼진 사이 곡이 넘어가도 커버가 나오게). 곡 정보 숨기기가 켜져 있으면 빈 맵 |
| `getState` | – | 지금 쥐고 있는 스냅샷 (+ `playing` · `positionMs`). 곡이 없으면 null. 앱을 다시 켰을 때 복원용 |
| `takeOpenPlayerRequest` | – | 알림을 눌러 앱이 **새로 켜졌는지** 한 번 알려 주고 비운다 |
| `setMixWithOthers` | bool | true면 오디오 포커스를 쓰지 않아 다른 앱 소리와 겹쳐 재생 (기본 false: 뺏기면 멈춤) |
| `setLoop` | `{startMs, endMs}` (둘 다 null이면 해제) | 현재 곡의 구간(A-B) 반복. 앱은 지정만 하고 판정은 `PlaybackHub`의 타이머가 한다: 재생 중 40ms마다 위치가 `endMs`에 닿았는지 보고 `startMs`로 `seekTo`한다 (되돌림은 기존 `position` 이벤트로 앱에 전해짐). 곡이 바뀌거나 대기열 끝에 닿으면 네이티브가 스스로 해제하고, 앱도 곡이 바뀌면 상태를 지운다 |
| `setSpeed` | double (0.5~2.0) | 재생 속도(음높이 유지). `ExoPlayer.setPlaybackSpeed`로 걸고 네이티브에도 저장해 앱 없이 프로세스가 새로 떠도 유지한다. 알림 · 잠금화면 진행 막대는 `SessionPlayer`가 이 배속으로 흘린다 (미리 듣기는 항상 1배) |
| `setOutputBehavior` | 맵 `pauseOnDisconnect` `resumeOnConnect` | 이어폰 분리 · 블루투스 끊김 때 일시정지할지(기본 true, `ACTION_AUDIO_BECOMING_NOISY`), 기기가 다시 연결되면 그 때문에 멈춘 재생을 이어갈지(기본 false, 끊긴 뒤 10분 안). 네이티브에도 저장해 앱이 꺼져도 지킨다 |
| `setSession` | 아래 맵 또는 null | null이면 알림을 치운다 (재생은 그대로) |

`setQueue` 스냅샷 맵: `items`(`id uri title artist album durationMs`의 목록, **Dart가 정한 순서**) `index` `playing` `repeat`(`off` `all` `one`) `positionMs`(없으면 같은 곡을 계속 듣는 것으로 보고 위치를 그대로 둔다) `extras`.
- `extras`는 셔플 여부 · 섞기 전 순서를 담은 JSON 문자열로 **네이티브가 쥔다**. 스냅샷에 `extras`가 없으면 지금 것을 그대로 두고(대기열 편집), `getState`로 돌려준다.
- `shuffleNew: true`면 `items`는 섞기 전 순서이고, 네이티브가 `index`번 곡을 맨 앞에 두고 나머지를 섞은 뒤 `queue` 이벤트로 새 순서를 알린다. 그 밖의 스냅샷은 이미 정해진 순서다 (ExoPlayer의 셔플 모드는 쓰지 않는다). 반복 모드만 네이티브가 안다 (`all`이면 끝에서 처음으로, `one`이면 한 곡 반복).

`setSession` 맵: `trackId title artist album artUri durationMs positionMs playing favorite preview favoriteLabel unfavoriteLabel closeLabel hideSongInfo hiddenTitle hiddenNote unknownArtist`.
`trackId`가 지금 재생 곡의 id와 같을 때만 이 맵의 내용(커버 · 좋아요 포함)을 알림에 쓴다. 앱이 꺼진 사이 곡이 넘어가면 맵은 옛 곡의 것이므로
네이티브가 대기열에 실린 곡 정보(`title artist album`)로 알림을 그린다(`hideSongInfo`면 숨김 글자). 좋아요 모양은 DB에서 직접 읽는다(아래 `알림 좋아요 버튼`).
`preview: true`면 소리는 Dart 쪽 미리 듣기 플레이어가 내므로 네이티브는 `playing` · `positionMs`를 그대로 보여 주고 조작은 모두 `command`로 돌려보낸다.
메인(`preview: false`)은 엔진 상태가 진실이라 `playing` · `positionMs`는 쓰지 않는다.

## EventChannel `music_app/playback/events`
| `type` | 필드 | 언제 |
|---|---|---|
| `playing` | `value` bool | 엔진이 소리를 내려는 상태가 바뀔 때. **다른 앱에 오디오 포커스를 뺏겨 멈추거나 돌려받아 재개할 때도 보낸다** |
| `position` | `ms` | 재생 중 약 250ms마다, 이동 직후 |
| `track` | `index` `id` | 엔진이 곡을 넘겼을 때 (곡 끝 · 알림 · 이어폰의 이전/다음). 목록을 바꾸느라 생긴 전환은 보내지 않는다. Dart는 `index`만 따라가고, 앱이 시킨 이동의 알림은 무시한다 |
| `queue` | `ids` `index` `shuffle` `repeat` | 대기열 순서 · 셔플 · 반복이 네이티브에서 바뀌었을 때 (셔플 켜기와 끄기, `shuffleNew`, 한 바퀴 뒤 재셔플, 알림 셔플 버튼, 반복 변경). Dart는 곡 구성이 같을 때만 순서를 따라가고, 다르면 무시한다 |
| `ended` | – | 반복 없이 대기열 끝까지 들었다 (열 수 없는 곡을 만나 더 갈 곳이 없을 때도) |
| `command` | `name` `positionMs?` | 알림 · 이어폰에서 온 조작: `favorite stop`, 미리 듣기 중엔 `play pause seek`도. 이전/다음은 네이티브가 직접 처리한다 |
| `openPlayer` | – | 앱이 떠 있는 중에 알림을 눌렀다 → 현재 곡의 플레이어 화면을 연다 |

## 수명 규칙
- 서비스 · 세션 · **대기열**은 네이티브가 쥔다. 대기열 · 위치 · 반복 · 알림 내용은 SharedPreferences(`PlaybackStore`)에도 저장해 두어, **프로세스가 죽어도** 블루투스 버튼(`MuloMediaButtonReceiver` → `MuloPlaybackService`)이나 앱 재시작으로 되살린다.
- **세션 정리 정책**: 닫기(X) · 알림 밀어서 지우기 · 정지 · 반복 없이 끝까지 재생 · 최근 작업에서 밀었는데 멈춰 있던 경우에는 알림을 치우고 미디어 세션을 release하며 이어 재생 불가(`resumable=false`)로 표시한다. 이 상태의 블루투스 / 이어폰 버튼은 무시한다. 대기열은 남아 앱에서 보이고, 앱에서 다시 재생하면 세션이 새로 만들어진다. 일시정지로 알림이 살아 있을 때(`resumable=true`)는 버튼으로 이어 재생하며, 프로세스가 죽었어도 저장된 대기열로 이어 재생한다.
- 앱을 끄거나(최근 작업에서 밀기) 화면이 사라져도 **재생은 계속**되고 다음 곡으로 이어진다.
- 앱이 다시 켜지면 Dart가 `getState`로 대기열 · 현재 곡 · 위치 · 반복 · `extras`를 읽어 상태를 복원한다 (보관함에서 사라진 곡은 건너뛰고 네이티브 대기열도 맞춘다). 이때는 네이티브를 다시 움직이지 않는다.
- 재생 · 일시정지 · 이동 · 이전 · 다음은 Dart 없이도 네이티브가 직접 처리한다 (화면이 사라져도 알림 버튼이 먹는다). 이전은 3초 넘게 들었으면 처음으로, 아니면 이전 곡(첫 곡이면 마지막 곡), 다음은 마지막 곡이면 전체 반복일 때만 처음으로. 좋아요는 Dart가 붙어 있으면 `command`로 넘기고, 없으면 네이티브가 DB를 직접 바꾼다.
- **알림 셔플 버튼**: 알림에는 늘 셔플이 있다(미리 듣기 제외). 아이콘은 `extras.shuffle`을 따른다. Dart 유무와 관계없이 네이티브가 직접 켜고 끈 뒤 `queue` 이벤트로 알린다: 켜면 듣던 곡을 맨 앞에 두고 나머지를 섞으며 섞기 전 순서를 `extras.original`에 적고, 끄면 `original` 순서로 되돌린다 (듣던 곡은 끊기지 않는다). 바뀐 `extras`는 저장돼 앱이 다시 켜지면 `getState`로 이어 받는다. 알림 버튼은 Dart 유무와 관계없이 늘 `[좋아요, 셔플]`이다(미리 듣기는 닫기만).
- **알림 좋아요 버튼**: 좋아요는 앱 DB `playlist_tracks`의 `playlist_id='favorites'` 줄이다. Dart가 붙어 있고 앱이 보낸 곡이 지금 곡이면 `command favorite`으로 넘긴다(화면의 drift 실시간 목록이 바로 바뀌도록). 아니면 `FavoriteStore`가 같은 줄을 `app_flutter/music_app.sqlite`에 직접 넣거나 지우고, 아이콘도 곡이 바뀔 때마다 DB에서 읽는다. DB 파일이 없으면 아무것도 하지 않는다(D-136).
- 셔플 한 바퀴: 셔플 중 마지막 → 처음으로 감기면(자동 · 다음 버튼 모두) 네이티브가 나머지를 새로 섞는다 (듣던 곡은 그대로, 방금 들은 곡이 바로 다음에 오지 않게). 앱이 붙어 있으면 `queue` 이벤트로 알린다.
- 알림을 눌러 앱이 **새로 켜졌을 때**는 복원 · 이동이 끝날 때까지 앱 쪽이 덮개(음표 아이콘)로 첫 화면을 가려서, 홈 → 플레이어로 차례로 넘어가는 것이 보이지 않게 한다.
- 알림을 누르면 PendingIntent(`com.mulo.app.OPEN_PLAYER`)로 앱을 연다. 앱이 떠 있으면 `openPlayer` 이벤트, 새로 켜졌으면 `takeOpenPlayerRequest`가 true를 준다. Dart는 대기열 복원을 끝낸 뒤 플레이어 화면(`/player`)을 연다.
- 오디오 포커스: 영상 등으로 빼앗기면 엔진이 멈추고 `playing:false`가 온다. `NowPlayingCubit`이 `isPlaying`을 맞춰 재생 버튼이 다시 먹는다.

## 출력 기기 (Android)
- `music_app/audio_output`: `current`(지금 출력 기기 `{type, name}`)와, 기기가 연결되거나 끊길 때 네이티브가 Dart로 보내는 `changed`. 앱은 `changed`를 받으면 `current`를 다시 읽어 플레이어(미니 플레이어)의 기기 이름을 바꾼다.
- 끊김 처리는 ExoPlayer의 `setHandleAudioBecomingNoisy`, 연결 때 이어 재생은 `AudioDeviceCallback`(블루투스 · 유선 · USB 기기가 추가될 때)로 네이티브가 한다. 이어 재생은 **끊김 때문에 멈춘 재생**을, 끊긴 지 10분 안에, 알림을 지우지 않았을 때만 한다 (프로세스가 살아 있을 때).
