import 'dart:async';

import '../../domain/entities/playback_snapshot.dart';
import '../../domain/entities/player_repeat_mode.dart';
import '../../domain/repositories/audio_player_repository.dart';
import '../datasources/audio_engine_source.dart';

/// 한 곡씩만 여는 엔진(just_audio) 위에서 대기열 순서대로 곡을 넘기는 재생 엔진 (데스크톱 · iOS).
/// Android 네이티브 엔진과 같은 약속: 곡 넘김은 여기서 하고, 넘기면 [watchTrackChange]로 알린다.
class JustAudioPlayerRepository implements AudioPlayerRepository {
  JustAudioPlayerRepository(this._source) {
    _source.completed.listen((_) => _onCompleted());
  }

  final AudioEngineSource _source;

  var _items = <PlaybackItem>[];
  var _index = 0;
  var _repeat = PlayerRepeatMode.off;

  /// 지금 엔진에 열려 있는 곡 id.
  String? _loadedId;

  final _trackChange = StreamController<PlaybackTrackChange>.broadcast();
  final _ended = StreamController<void>.broadcast();

  PlaybackItem? get _current =>
      _index >= 0 && _index < _items.length ? _items[_index] : null;

  @override
  Stream<Duration> watchPosition() => _source.position;

  @override
  Stream<PlaybackTrackChange> watchTrackChange() => _trackChange.stream;

  @override
  Stream<void> watchEnded() => _ended.stream;

  @override
  Stream<bool> watchPlaying() => _source.playing;

  @override
  Stream<void> watchOpenPlayer() => const Stream.empty();

  Future<void> _open(PlaybackItem item) async {
    _loadedId = null;
    await _source.load(item.uri);
    _loadedId = item.id;
  }

  @override
  Future<void> setQueue(PlaybackSnapshot snapshot) async {
    _items = snapshot.items;
    _index = snapshot.index;
    _repeat = snapshot.repeat;
    final current = _current;
    if (current == null) {
      _loadedId = null;
      await _source.pause();
      return;
    }
    if (_loadedId != current.id) {
      await _open(current);
      final at = snapshot.position;
      if (at != null && at > Duration.zero) await _source.seek(at);
    } else if (snapshot.position != null) {
      await _source.seek(snapshot.position!);
    }
    await (snapshot.playing ? play() : pause());
  }

  @override
  Future<void> skipTo(int index) async {
    _index = index;
    final current = _current;
    if (current == null) return;
    await _open(current);
  }

  // just_audio의 play()는 곡이 끝날 때까지 끝나지 않아 기다리지 않는다.
  @override
  Future<void> play() async {
    unawaited(_source.play());
  }

  @override
  Future<void> pause() => _source.pause();

  @override
  Future<void> seek(Duration position) => _source.seek(position);

  /// 곡 끝: 한 곡 반복이면 처음부터 다시, 아니면 다음 곡 (마지막 곡이면 반복 설정에 따라).
  Future<void> _onCompleted() async {
    final current = _current;
    if (current == null) return;
    final last = _index == _items.length - 1;
    if (_repeat == PlayerRepeatMode.one ||
        (last && _repeat == PlayerRepeatMode.all && _items.length == 1)) {
      await _source.seek(Duration.zero);
      await play();
      return;
    }
    if (last && _repeat == PlayerRepeatMode.off) {
      _ended.add(null);
      return;
    }
    final next = last ? 0 : _index + 1;
    _index = next;
    try {
      await _open(_items[next]);
    } on Object {
      _ended.add(null);
      return;
    }
    _trackChange.add(PlaybackTrackChange(next, _items[next].id));
    await play();
  }

  /// 이 엔진은 프로세스와 함께 사라지므로 되살릴 대기열이 없다.
  @override
  Future<PlaybackSnapshot?> restore() async => null;

  @override
  Future<bool> takeOpenPlayerRequest() async => false;
}
