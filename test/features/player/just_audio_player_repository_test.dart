import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/player/data/datasources/audio_engine_source.dart';
import 'package:music_download_play_app/features/player/data/repositories/just_audio_player_repository.dart';
import 'package:music_download_play_app/features/player/domain/entities/playback_snapshot.dart';
import 'package:music_download_play_app/features/player/domain/entities/player_repeat_mode.dart';

class _FakeEngine implements AudioEngineSource {
  final _completed = StreamController<void>.broadcast();
  final calls = <String>[];
  final failing = <String>{};

  void complete() => _completed.add(null);

  @override
  Stream<Duration> get position => const Stream.empty();

  @override
  Stream<bool> get playing => const Stream.empty();

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> load(String uri) async {
    calls.add('load:$uri');
    if (failing.contains(uri)) throw StateError('cannot load');
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(Duration position) async =>
      calls.add('seek:${position.inMilliseconds}');
  @override
  Future<void> setSpeed(double speed) async => calls.add('speed:$speed');
}

PlaybackSnapshot _snapshot({
  int index = 0,
  PlayerRepeatMode repeat = PlayerRepeatMode.off,
  Duration? position,
  bool playing = true,
  int count = 3,
}) => PlaybackSnapshot(
  items: [
    for (var i = 0; i < count; i++)
      PlaybackItem(id: 't$i', uri: 'file:///t$i.mp3', title: 'T$i'),
  ],
  index: index,
  playing: playing,
  repeat: repeat,
  position: position,
);

/// 한 곡씩만 여는 엔진 위에서 대기열 순서대로 곡을 넘기는 재생 엔진.
void main() {
  late _FakeEngine engine;
  late JustAudioPlayerRepository repo;
  final changes = <PlaybackTrackChange>[];
  var ended = 0;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    engine = _FakeEngine();
    repo = JustAudioPlayerRepository(engine);
    changes.clear();
    ended = 0;
    repo.watchTrackChange().listen(changes.add);
    repo.watchEnded().listen((_) => ended++);
  });

  test('대기열을 받으면 현재 곡을 불러와 재생한다', () async {
    await repo.setQueue(
      _snapshot(index: 1, position: const Duration(seconds: 5)),
    );
    expect(engine.calls, ['load:file:///t1.mp3', 'seek:5000', 'play']);
  });

  test('현재 곡이 그대로면 다시 불러오지 않는다', () async {
    await repo.setQueue(_snapshot());
    engine.calls.clear();
    await repo.setQueue(_snapshot(repeat: PlayerRepeatMode.all));
    expect(engine.calls, ['play']);
  });

  test('곡이 끝나면 다음 곡으로 넘기고 알린다', () async {
    await repo.setQueue(_snapshot());
    engine.calls.clear();
    engine.complete();
    await settle();
    await settle();
    expect(engine.calls, ['load:file:///t1.mp3', 'play']);
    expect(changes, [const PlaybackTrackChange(1, 't1')]);
  });

  test('마지막 곡이 끝나면 반복이 꺼져 있을 때 끝났다고 알린다', () async {
    await repo.setQueue(_snapshot(index: 2));
    engine.calls.clear();
    engine.complete();
    await settle();
    await settle();
    expect(ended, 1);
    expect(changes, isEmpty);
    // 첫 곡으로 돌아가 멈춰 둔다.
    expect(engine.calls, ['load:file:///t0.mp3', 'pause']);
  });

  test('전체 반복이면 마지막 곡 뒤에 처음 곡으로 돌아간다', () async {
    await repo.setQueue(_snapshot(index: 2, repeat: PlayerRepeatMode.all));
    engine.calls.clear();
    engine.complete();
    await settle();
    await settle();
    expect(engine.calls, ['load:file:///t0.mp3', 'play']);
    expect(changes, [const PlaybackTrackChange(0, 't0')]);
  });

  test('한 곡 반복이면 같은 곡을 처음부터 다시 재생한다', () async {
    await repo.setQueue(_snapshot(repeat: PlayerRepeatMode.one));
    engine.calls.clear();
    engine.complete();
    await settle();
    await settle();
    expect(engine.calls, ['seek:0', 'play']);
    expect(changes, isEmpty);
  });

  test('곡 하나뿐인 전체 반복도 처음부터 다시 재생한다', () async {
    await repo.setQueue(_snapshot(count: 1, repeat: PlayerRepeatMode.all));
    engine.calls.clear();
    engine.complete();
    await settle();
    await settle();
    expect(engine.calls, ['seek:0', 'play']);
  });

  test('다음 곡을 못 불러오면 끝난 것으로 본다', () async {
    await repo.setQueue(_snapshot());
    engine.failing.add('file:///t1.mp3');
    engine.complete();
    await settle();
    await settle();
    expect(ended, 1);
  });

  test('앱이 시킨 이동은 곡 넘김으로 알리지 않는다', () async {
    await repo.setQueue(_snapshot());
    await repo.skipTo(2);
    await settle();
    expect(changes, isEmpty);
  });

  test('이 엔진은 되살릴 대기열이 없다', () async {
    expect(await repo.restore(), isNull);
    expect(await repo.takeOpenPlayerRequest(), isFalse);
  });
}
