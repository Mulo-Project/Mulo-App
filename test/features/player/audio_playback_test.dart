import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/player/domain/entities/playback_snapshot.dart';
import 'package:music_download_play_app/features/player/domain/usecases/audio_playback_usecases.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

/// 재생 상태 Cubit과 재생 엔진 연결 (가짜 엔진). 곡 넘김은 엔진이 하고 Cubit은 따라간다.
void main() {
  late FakeAudioPlayer engine;
  late NowPlayingCubit cubit;
  final tracks = TestData.tracks.take(3).toList();

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  NowPlayingCubit makeCubit({Random? random}) => NowPlayingCubit(
    random: random,
    audio: AudioPlayback(
      watchPosition: WatchAudioPosition(engine),
      watchTrackChange: WatchAudioTrackChange(engine),
      watchEnded: WatchAudioEnded(engine),
      watchPlaying: WatchAudioPlaying(engine),
      watchOpenPlayer: WatchOpenPlayer(engine),
      setQueue: SetAudioQueue(engine),
      skipTo: SkipAudioTo(engine),
      play: PlayAudio(engine),
      pause: PauseAudio(engine),
      seek: SeekAudio(engine),
      setLoop: SetAudioLoop(engine),
      restore: RestoreAudioQueue(engine),
      takeOpenPlayerRequest: TakeOpenPlayerRequest(engine),
    ),
  );

  setUp(() {
    engine = FakeAudioPlayer();
    cubit = makeCubit();
  });
  tearDown(() => cubit.close());

  test('구간 반복: 시작 → 끝을 정하면 엔진에 구간이 가고, 다시 누르면 해제된다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.emitPosition(const Duration(seconds: 5));
    await settle();
    cubit.cycleLoop();
    expect(cubit.state.loopStart, const Duration(seconds: 5));
    expect(cubit.state.looping, isFalse);
    // 끝이 시작 뒤 1초 안이면 무시한다.
    cubit.cycleLoop();
    expect(cubit.state.loopEnd, isNull);
    engine.emitPosition(const Duration(seconds: 12));
    await settle();
    cubit.cycleLoop();
    await settle();
    expect(cubit.state.looping, isTrue);
    expect(engine.calls.last, 'loop:5000-12000');
    cubit.cycleLoop();
    await settle();
    expect(cubit.state.loopStart, isNull);
    expect(engine.calls.last, 'loop:off');
  });

  test('구간 반복: 두 번째 지점이 앞이면 앞쪽이 시작이 된다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.emitPosition(const Duration(seconds: 20));
    await settle();
    cubit.cycleLoop();
    engine.emitPosition(const Duration(seconds: 7));
    await settle();
    cubit.cycleLoop();
    await settle();
    expect(cubit.state.looping, isTrue);
    expect(cubit.state.loopStart, const Duration(seconds: 7));
    expect(cubit.state.loopEnd, const Duration(seconds: 20));
    expect(engine.calls.last, 'loop:7000-20000');
  });

  test('구간 반복은 곡이 바뀌면 풀린다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.emitPosition(const Duration(seconds: 2));
    await settle();
    cubit.cycleLoop();
    engine.emitPosition(const Duration(seconds: 8));
    await settle();
    cubit.cycleLoop();
    await settle();
    expect(cubit.state.looping, isTrue);
    engine.emitTrack(1);
    await settle();
    expect(cubit.state.loopStart, isNull);
    expect(cubit.state.loopEnd, isNull);
  });

  test('곡을 고르면 대기열 전체를 엔진에 보내 재생한다', () async {
    cubit.playQueue(tracks);
    await settle();
    expect(engine.calls, ['queue:${tracks[0].uri}']);
    expect(engine.snapshot!.items.map((i) => i.id), tracks.map((t) => t.id));
    expect(engine.snapshot!.index, 0);
    expect(engine.snapshot!.playing, isTrue);
    expect(engine.playing, isTrue);
  });

  test('일시정지 · 재생은 엔진에 전해진다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.togglePlay();
    await settle();
    expect(engine.playing, isFalse);
    cubit.togglePlay();
    await settle();
    expect(engine.playing, isTrue);
  });

  test('다른 앱이 오디오 포커스를 가져가 엔진이 멈추면 재생 상태도 멈춘다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.emitPlaying(false);
    await settle();
    expect(cubit.state.isPlaying, isFalse);
    // 재생 버튼이 다시 먹는다.
    cubit.togglePlay();
    await settle();
    expect(cubit.state.isPlaying, isTrue);
    expect(engine.playing, isTrue);
  });

  test('포커스를 돌려받아 엔진이 다시 시작하면 재생 상태도 따라간다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.emitPlaying(false);
    await settle();
    engine.emitPlaying(true);
    await settle();
    expect(cubit.state.isPlaying, isTrue);
  });

  test('곡을 불러오는 동안 엔진이 보낸 정지 신호는 상태에 넣지 않는다', () async {
    cubit.playQueue(tracks);
    engine.emitPlaying(false); // 불러오기 작업이 아직 끝나기 전
    await settle();
    expect(cubit.state.isPlaying, isTrue);
  });

  test('다음 곡 · 이전 곡은 대기열을 다시 보내지 않고 엔진을 옮긴다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.calls.clear();
    cubit.next();
    await settle();
    expect(engine.calls, ['skip:1', 'play']);
    expect(engine.loaded, tracks[1].uri);
    expect(engine.playing, isTrue);
    cubit.previous();
    await settle();
    expect(engine.loaded, tracks[0].uri);
  });

  test('엔진의 재생 위치가 상태로 돌아온다 (엔진을 다시 움직이지 않는다)', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.calls.clear();
    engine.emitPosition(const Duration(seconds: 5));
    await settle();
    expect(cubit.state.position, const Duration(seconds: 5));
    expect(engine.calls, isEmpty);
  });

  test('위치를 옮기면 엔진도 옮긴다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.seekTo(const Duration(seconds: 30));
    await settle();
    expect(engine.lastSeek, const Duration(seconds: 30));
  });

  test('엔진이 스스로 다음 곡으로 넘기면 상태가 따라가고 엔진은 다시 움직이지 않는다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.calls.clear();
    engine.emitTrack(1);
    await settle();
    expect(cubit.state.index, 1);
    expect(cubit.state.position, Duration.zero);
    expect(engine.calls, isEmpty);
  });

  test('엔진이 알린 곡이 대기열과 맞지 않으면 무시한다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.emitTrack(1);
    await settle();
    engine.index = 2;
    // 대기열 2번이 아닌 곡 id를 알려 온다.
    engine.snapshot = PlaybackSnapshot(
      items: [
        for (final t in tracks)
          PlaybackItem(id: 'x${t.id}', uri: t.uri, title: t.title),
      ],
      index: 2,
      playing: true,
    );
    engine.emitTrack(2);
    await settle();
    expect(cubit.state.index, 1);
  });

  test('대기열 끝까지 들으면 첫 곡으로 돌아가 멈춘다', () async {
    cubit.playQueue(tracks, index: 2);
    await settle();
    engine.end();
    await settle();
    expect(cubit.state.isPlaying, isFalse);
    expect(cubit.state.index, 0);
    expect(cubit.state.position, Duration.zero);
  });

  test('반복 모드는 대기열과 함께 엔진에 전해진다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.cycleRepeat();
    await settle();
    expect(engine.snapshot!.repeat, PlayerRepeatMode.all);
    // 듣던 곡은 그대로: 위치를 건드리지 않는다.
    expect(engine.snapshot!.position, isNull);
  });

  test('다음에 재생은 듣던 곡의 위치를 건드리지 않고 목록만 보낸다', () async {
    cubit.playQueue(tracks.take(2).toList());
    await settle();
    engine.emitPosition(const Duration(seconds: 12));
    await settle();
    cubit.playNext(tracks[2]);
    await settle();
    expect(engine.snapshot!.items.map((i) => i.id), [
      tracks[0].id,
      tracks[2].id,
      tracks[1].id,
    ]);
    expect(engine.snapshot!.index, 0);
    expect(engine.snapshot!.position, isNull);
    expect(cubit.state.position, const Duration(seconds: 12));
  });

  test('순서를 옮겨도 듣던 곡은 그대로이고 위치만 새 번호로 보낸다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.moveInQueue(0, 2);
    await settle();
    expect(engine.snapshot!.index, 2);
    expect(engine.snapshot!.current!.id, tracks[0].id);
    expect(engine.snapshot!.position, isNull);
  });

  test('셔플 여부와 원래 순서는 extras로 엔진에 맡긴다', () async {
    cubit.playQueue(tracks);
    cubit.toggleShuffle();
    await settle();
    final extras = jsonDecode(engine.snapshot!.extras) as Map;
    expect(extras['shuffle'], isTrue);
    expect(extras['original'], tracks.map((t) => t.id));
  });

  test('셔플 중 엔진이 한 바퀴를 돌아 처음으로 오면 순서를 새로 섞는다', () async {
    cubit.playQueue(tracks);
    cubit.toggleShuffle(currentFirst: true);
    await settle();
    final order = cubit.state.queue.map((t) => t.id).toList();
    engine.emitTrack(1);
    await settle();
    engine.emitTrack(2);
    await settle();
    engine.emitTrack(0);
    await settle();
    expect(cubit.state.index, 0);
    // 지금 곡은 그대로 맨 앞이고, 엔진에도 새 순서가 전해졌다.
    expect(cubit.state.track!.id, order.first);
    expect(engine.snapshot!.current!.id, order.first);
    expect(
      engine.snapshot!.items.map((i) => i.id),
      cubit.state.queue.map((t) => t.id),
    );
  });

  test('곡을 못 불러오면 재생을 멈춘다', () async {
    engine.failing.add(tracks[0].uri);
    cubit.playQueue(tracks);
    await settle();
    await settle();
    expect(cubit.state.isPlaying, isFalse);
  });

  test('주소가 없는 곡도 못 불러온 것으로 본다', () async {
    cubit.playQueue([
      Track(
        id: 'none',
        title: 'No file',
        artist: '',
        album: '',
        duration: const Duration(minutes: 1),
        addedAt: DateTime(2026),
      ),
    ]);
    await settle();
    expect(cubit.state.isPlaying, isFalse);
    expect(engine.loaded, isNull);
  });

  test('불러오는 동안 온 옛 재생 위치는 무시한다', () async {
    cubit.playQueue(tracks);
    engine.emitPosition(const Duration(seconds: 99));
    await settle();
    expect(cubit.state.position, isNot(const Duration(seconds: 99)));
  });

  test('대기열을 비우면 엔진도 비운다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.clearQueue();
    await settle();
    expect(engine.snapshot!.items, isEmpty);
    expect(engine.playing, isFalse);
  });

  group('앱을 다시 켰을 때', () {
    PlaybackSnapshot fromEngine({String extras = ''}) => PlaybackSnapshot(
      items: [
        for (final t in tracks)
          PlaybackItem(id: t.id, uri: t.uri, title: t.title),
      ],
      index: 1,
      playing: true,
      repeat: PlayerRepeatMode.all,
      position: const Duration(seconds: 42),
      extras: extras,
    );

    test('엔진이 쥔 대기열 · 현재 곡 · 위치 · 반복을 되살린다 (엔진은 다시 움직이지 않는다)', () async {
      engine.restoreSnapshot = fromEngine();
      await cubit.restore((id) => tracks.where((t) => t.id == id).firstOrNull);
      await settle();
      expect(cubit.state.queue, tracks);
      expect(cubit.state.index, 1);
      expect(cubit.state.isPlaying, isTrue);
      expect(cubit.state.position, const Duration(seconds: 42));
      expect(cubit.state.repeat, PlayerRepeatMode.all);
      expect(engine.calls, isEmpty);
    });

    test('셔플과 원래 순서도 되살려 셔플을 끄면 원래 순서로 돌아간다', () async {
      final original = tracks.reversed.toList();
      engine.restoreSnapshot = fromEngine(
        extras: jsonEncode({
          'shuffle': true,
          'original': [for (final t in original) t.id],
        }),
      );
      await cubit.restore((id) => tracks.where((t) => t.id == id).firstOrNull);
      expect(cubit.state.shuffle, isTrue);
      cubit.toggleShuffle();
      expect(cubit.state.queue, original);
    });

    test('보관함에서 사라진 곡은 건너뛰고 엔진의 대기열도 맞춘다', () async {
      engine.restoreSnapshot = fromEngine();
      final missing = tracks[0].id;
      await cubit.restore(
        (id) =>
            id == missing ? null : tracks.where((t) => t.id == id).firstOrNull,
      );
      await settle();
      expect(cubit.state.queue, tracks.skip(1));
      expect(cubit.state.track, tracks[1]);
      expect(cubit.state.index, 0);
      expect(engine.snapshot!.items.length, 2);
      expect(engine.snapshot!.index, 0);
    });

    test('이미 곡이 있으면 되살리지 않는다', () async {
      cubit.playQueue([tracks[2]]);
      await settle();
      engine.restoreSnapshot = fromEngine();
      await cubit.restore((id) => tracks.where((t) => t.id == id).firstOrNull);
      expect(cubit.state.queue, [tracks[2]]);
    });

    test('엔진에 대기열이 없으면 아무것도 하지 않는다', () async {
      await cubit.restore((_) => tracks.first);
      expect(cubit.state.queue, isEmpty);
    });
  });

  group('알림을 눌러 플레이어 화면 열기', () {
    test('앱이 켜져 있는 중에 누르면 요청이 흘러온다', () async {
      var opened = 0;
      final sub = cubit.openPlayerRequests.listen((_) => opened++);
      engine.emitOpenPlayer();
      await settle();
      expect(opened, 1);
      await sub.cancel();
    });

    test('앱이 새로 켜졌을 때는 한 번만 알려 주고 비운다', () async {
      engine.openPlayerRequested = true;
      expect(await cubit.takeOpenPlayerRequest(), isTrue);
      expect(await cubit.takeOpenPlayerRequest(), isFalse);
    });
  });

  test('엔진 없이도 화면 상태는 움직인다', () {
    final plain = NowPlayingCubit()..playQueue(tracks);
    expect(plain.state.track, tracks.first);
    plain.close();
  });
}
