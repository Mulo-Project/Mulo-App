import '../entities/playback_snapshot.dart';
import '../entities/player_repeat_mode.dart';

/// 오디오 재생 엔진. 앱이 보내 준 대기열 스냅샷을 순서대로 재생하고 곡 넘김은 엔진이 한다.
abstract interface class AudioPlayerRepository {
  /// 재생 위치. 재생 중에만 계속 흘러나온다.
  Stream<Duration> watchPosition();

  /// 엔진이 스스로 다른 곡으로 넘어갔을 때 (곡 끝, 알림 · 이어폰의 이전 · 다음).
  /// 앱이 시킨 이동([setQueue] · [skipTo])에는 보내지 않는다.
  Stream<PlaybackTrackChange> watchTrackChange();

  /// 엔진이 대기열의 순서 · 셔플 · 반복을 바꿨을 때 (셔플 켜기와 끄기, 한 바퀴 뒤 재셔플, 알림 셔플 버튼).
  /// 대기열 순서의 원본은 엔진이고 앱은 이 이벤트를 비춘다.
  Stream<PlaybackQueueChange> watchQueue();

  /// 반복 없이 대기열 끝까지 재생했을 때.
  Stream<void> watchEnded();

  /// 엔진이 실제로 소리를 내려는 상태가 바뀔 때마다. 앱이 시킨 재생 · 정지뿐 아니라
  /// 다른 앱에 오디오 포커스를 뺏겨 멈추거나 돌려받아 다시 시작할 때도 알려 준다.
  Stream<bool> watchPlaying();

  /// 앱이 켜져 있는 중에 알림을 눌러 플레이어 화면을 열라는 요청.
  Stream<void> watchOpenPlayer();

  // 대기열을 바꾸는 명령([setQueue] · [playNext] · [addToQueue] · [removeFromQueue] · [moveInQueue] ·
  // [setShuffle] · [setRepeat])은 끝나면 엔진의 대기열 모습을 돌려준다. 앱은 그것을 그대로 비춘다.
  // 알 수 없으면 null.

  /// 대기열을 통째로 바꾼다. 현재 곡이 같으면 재생을 끊지 않는다.
  /// 현재 곡을 못 불러오면 던진다.
  Future<PlaybackQueueChange?> setQueue(PlaybackSnapshot snapshot);

  /// 지금 곡 바로 뒤에 끼운다. 이미 대기열에 있는 곡이면 그 자리를 옮긴다 (지금 곡이면 그대로).
  Future<PlaybackQueueChange?> playNext(PlaybackItem item);

  /// 대기열 맨 뒤에 붙인다. 이미 있는 곡이면 건너뛴다.
  Future<PlaybackQueueChange?> addToQueue(PlaybackItem item);

  /// 곡 하나를 뺀다. 지금 곡이면 다음 곡(마지막이었으면 새 마지막 곡)으로 처음부터 넘어가고 재생 상태는 그대로다.
  /// 마지막 한 곡이면 대기열이 비고 멈춘다.
  Future<PlaybackQueueChange?> removeFromQueue(String id);

  /// [from]번 곡을 [to] 자리로 옮긴다 ([to]는 옮긴 뒤의 자리). 듣던 곡은 그대로 이어서 재생한다.
  Future<PlaybackQueueChange?> moveInQueue(int from, int to);

  /// 셔플을 켜고 끈다. 엔진이 지금 곡을 맨 앞에 두고 나머지를 섞어 [watchQueue]로 알린다.
  /// 끄면 섞기 전 순서로 되돌린다. 듣던 곡은 끊기지 않는다.
  Future<PlaybackQueueChange?> setShuffle(bool on);

  /// 반복 모드를 바꾼다.
  Future<PlaybackQueueChange?> setRepeat(PlayerRepeatMode mode);

  /// 대기열은 그대로 두고 [index]번 곡으로 처음부터 옮긴다.
  Future<void> skipTo(int index);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  /// 현재 곡의 [start]~[end] 구간만 반복한다. 둘 다 null이면 해제.
  /// 곡이 바뀌면 엔진이 스스로 해제한다.
  Future<void> setLoop(Duration? start, Duration? end);

  /// 엔진이 지금 쥐고 있는 대기열 (앱을 다시 켰을 때 복원용). 없으면 null.
  Future<PlaybackSnapshot?> restore();

  /// 알림을 눌러 앱이 새로 켜졌는지 한 번 알려 주고 비운다.
  Future<bool> takeOpenPlayerRequest();
}
