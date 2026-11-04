import 'dart:io';

import '../../../../core/platform/native_playback_channel.dart';
import '../../domain/entities/playback_snapshot.dart';
import '../../domain/entities/player_repeat_mode.dart';
import '../../domain/repositories/audio_player_repository.dart';

/// Android 재생 엔진: 네이티브 서비스(ExoPlayer)가 대기열을 쥐고 소리를 내며 곡도 넘긴다.
/// 앱이 꺼져도 다음 곡으로 이어지고, 앱을 다시 켜면 [restore]로 대기열을 돌려받는다.
/// 다른 앱에 오디오 포커스를 뺏겨 멈추면 [watchPlaying]으로 알려 준다.
class NativeAudioPlayerRepository implements AudioPlayerRepository {
  NativeAudioPlayerRepository(this._channel);

  final NativePlaybackChannel _channel;

  @override
  Stream<Duration> watchPosition() => _channel.events
      .where((e) => e['type'] == 'position')
      .map((e) => Duration(milliseconds: (e['ms'] as num).toInt()));

  @override
  Stream<PlaybackTrackChange> watchTrackChange() => _channel.events
      .where((e) => e['type'] == 'track')
      .map(
        (e) => PlaybackTrackChange((e['index'] as num).toInt(), '${e['id']}'),
      );

  @override
  Stream<PlaybackQueueChange> watchQueue() => _channel.events
      .where((e) => e['type'] == 'queue')
      .map(_queueOf)
      .where((c) => c != null)
      .cast<PlaybackQueueChange>();

  @override
  Stream<void> watchEnded() =>
      _channel.events.where((e) => e['type'] == 'ended');

  @override
  Stream<bool> watchPlaying() => _channel.events
      .where((e) => e['type'] == 'playing')
      .map((e) => e['value'] == true);

  @override
  Stream<void> watchOpenPlayer() =>
      _channel.events.where((e) => e['type'] == 'openPlayer');

  static String _uri(String uri) => uri.isEmpty || uri.contains('://')
      ? uri
      : Uri.file(uri, windows: Platform.isWindows).toString();

  static Map<String, Object?> _itemMap(PlaybackItem i) => {
    'id': i.id,
    'uri': _uri(i.uri),
    'title': i.title,
    'artist': i.artist,
    'album': i.album,
    'durationMs': i.duration.inMilliseconds,
  };

  /// 네이티브가 돌려준 대기열 모습 (`ids` `index` `shuffle` `repeat`)을 읽는다. 없으면 null.
  static PlaybackQueueChange? _queueOf(Map<Object?, Object?>? map) {
    final ids = map?['ids'];
    if (map == null || ids is! List) return null;
    return PlaybackQueueChange(
      ids: [for (final id in ids) '$id'],
      index: (map['index'] as num?)?.toInt() ?? 0,
      shuffle: map['shuffle'] == true,
      repeat: PlayerRepeatMode.values.firstWhere(
        (m) => m.name == map['repeat'],
        orElse: () => PlayerRepeatMode.off,
      ),
    );
  }

  @override
  Future<PlaybackQueueChange?> playNext(PlaybackItem item) async =>
      _queueOf(await _channel.playNext(_itemMap(item)));

  @override
  Future<PlaybackQueueChange?> addToQueue(PlaybackItem item) async =>
      _queueOf(await _channel.addToQueue(_itemMap(item)));

  @override
  Future<PlaybackQueueChange?> removeFromQueue(String id) async =>
      _queueOf(await _channel.removeFromQueue(id));

  @override
  Future<PlaybackQueueChange?> moveInQueue(int from, int to) async =>
      _queueOf(await _channel.moveInQueue(from, to));

  @override
  Future<PlaybackQueueChange?> setQueue(PlaybackSnapshot snapshot) async =>
      _queueOf(await _channel.setQueue({
    'items': [for (final i in snapshot.items) _itemMap(i)],
    'index': snapshot.index,
    'playing': snapshot.playing,
    'repeat': snapshot.repeat.name,
    'positionMs': snapshot.position?.inMilliseconds,
    // 비어 있으면 보내지 않는다: 셔플 상태는 네이티브가 쥐고 있는 것을 그대로 둔다.
    if (snapshot.extras.isNotEmpty) 'extras': snapshot.extras,
    if (snapshot.shuffleNew) 'shuffleNew': true,
  }));

  @override
  Future<PlaybackQueueChange?> setShuffle(bool on) async =>
      _queueOf(await _channel.setShuffle(on));

  @override
  Future<PlaybackQueueChange?> setRepeat(PlayerRepeatMode mode) async =>
      _queueOf(await _channel.setRepeat(mode.name));

  @override
  Future<void> skipTo(int index) => _channel.skipTo(index);

  @override
  Future<void> play() => _channel.play();

  @override
  Future<void> pause() => _channel.pause();

  @override
  Future<void> seek(Duration position) => _channel.seek(position);

  @override
  Future<void> setLoop(Duration? start, Duration? end) =>
      _channel.setLoop(start, end);

  @override
  Future<PlaybackSnapshot?> restore() async {
    final map = await _channel.getState();
    final raw = map?['items'];
    if (map == null || raw is! List || raw.isEmpty) return null;
    return PlaybackSnapshot(
      items: [
        for (final i in raw.whereType<Map<Object?, Object?>>())
          PlaybackItem(
            id: '${i['id']}',
            uri: '${i['uri']}',
            title: '${i['title'] ?? ''}',
            artist: '${i['artist'] ?? ''}',
            album: '${i['album'] ?? ''}',
            duration: Duration(
              milliseconds: (i['durationMs'] as num?)?.toInt() ?? 0,
            ),
          ),
      ],
      index: (map['index'] as num?)?.toInt() ?? 0,
      playing: map['playing'] == true,
      repeat: PlayerRepeatMode.values.firstWhere(
        (m) => m.name == map['repeat'],
        orElse: () => PlayerRepeatMode.off,
      ),
      position: Duration(
        milliseconds: (map['positionMs'] as num?)?.toInt() ?? 0,
      ),
      extras: '${map['extras'] ?? ''}',
    );
  }

  @override
  Future<bool> takeOpenPlayerRequest() => _channel.takeOpenPlayerRequest();
}
