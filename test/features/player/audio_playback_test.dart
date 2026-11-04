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
      watchQueue: WatchAudioQueue(engine),
      playNext: PlayAudioNext(engine),
      addToQueue: AddAudioToQueue(engine),
      removeFromQueue: RemoveAudioFromQueue(engine),
      moveInQueue: MoveAudioInQueue(engine),
      setShuffle: SetAudioShuffle(engine),
      setRepeat: SetAudioRepeat(engine),
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

  test('반복 모드는 엔진에 명령으로 보내고 듣던 곡은 건드리지 않는다', () async {
    cubit.playQueue(tracks);
    await settle();
    final before = engine.calls.where((c) => c.startsWith('queue')).length;
    cubit.cycleRepeat();
    await settle();
    expect(cubit.state.repeat, PlayerRepeatMode.all);
    expect(engine.calls, contains('repeat:all'));
    expect(engine.repeat, PlayerRepeatMode.all);
    // 대기열을 다시 보내지 않는다.
    expect(engine.calls.where((c) => c.startsWith('queue')).length, before);
  });

  test('다음에 재생은 엔진에 편집 명령만 보내고 듣던 곡의 위치를 건드리지 않는다', () async {
    cubit.playQueue(tracks.take(2).toList());
    await settle();
    engine.emitPosition(const Duration(seconds: 12));
    await settle();
    final queueCalls = engine.calls.where((c) => c.startsWith('queue')).length;
    cubit.playNext(tracks[2]);
    await settle();
    expect(engine.calls, contains('next:${tracks[2].id}'));
    // 대기열을 통째로 다시 보내지 않는다.
    expect(engine.calls.where((c) => c.startsWith('queue')).length, queueCalls);
    expect(engine.snapshot!.items.map((i) => i.id), [
      tracks[0].id,
      tracks[2].id,
      tracks[1].id,
    ]);
    expect(engine.snapshot!.index, 0);
    expect(engine.snapshot!.position, isNull);
    expect(cubit.state.queue.map((t) => t.id), [
      tracks[0].id,
      tracks[2].id,
      tracks[1].id,
    ]);
    expect(cubit.state.position, const Duration(seconds: 12));
  });

  test('맨 뒤에 붙이기도 편집 명령으로 보낸다', () async {
    cubit.playQueue(tracks.take(2).toList());
    await settle();
    cubit.addToQueue(tracks[2]);
    await settle();
    expect(engine.calls, contains('add:${tracks[2].id}'));
    expect(engine.snapshot!.items.last.id, tracks[2].id);
    expect(cubit.state.queue.last, tracks[2]);
    expect(cubit.state.index, 0);
  });

  test('듣던 곡을 빼면 다음 곡으로 넘어가고 엔진에는 빼기 명령만 간다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.removeFromQueue(tracks[0]);
    await settle();
    expect(engine.calls, contains('remove:${tracks[0].id}'));
    expect(cubit.state.queue, tracks.skip(1));
    expect(cubit.state.track, tracks[1]);
    expect(cubit.state.index, 0);
    expect(engine.snapshot!.current!.id, tracks[1].id);
    expect(cubit.state.isPlaying, isTrue);
  });

  test('순서를 옮겨도 듣던 곡은 그대로이고 엔진에는 옮기기 명령만 간다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.moveInQueue(0, 2);
    await settle();
    expect(engine.calls, contains('move:0-2'));
    expect(engine.snapshot!.index, 2);
    expect(engine.snapshot!.current!.id, tracks[0].id);
    expect(engine.snapshot!.position, isNull);
    expect(cubit.state.index, 2);
  });

  test('셔플은 엔진에 명령으로 맡기고, 엔진이 알려 준 순서를 비춘다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.toggleShuffle();
    await settle();
    expect(engine.calls, contains('shuffle:true'));
    expect(cubit.state.shuffle, isTrue);
    // 가짜 엔진은 지금 곡을 맨 앞에 두고 나머지를 뒤집는다.
    expect(cubit.state.queue.map((t) => t.id), [
      tracks[0].id,
      tracks[2].id,
      tracks[1].id,
    ]);
    expect(cubit.state.track, tracks[0]);
    cubit.toggleShuffle();
    await settle();
    expect(engine.calls, contains('shuffle:false'));
    expect(cubit.state.shuffle, isFalse);
    expect(cubit.state.queue, tracks);
  });

  test('셔플로 새 대기열을 시작하면 엔진이 섞고 앱은 그 순서를 비춘다', () async {
    cubit.playShuffled(tracks);
    await settle();
    expect(engine.snapshot!.index, 0);
    expect(cubit.state.shuffle, isTrue);
    expect(cubit.state.index, 0);
    expect(
      cubit.state.queue.map((t) => t.id),
      engine.snapshot!.items.map((i) => i.id),
    );
  });

  test('엔진이 스스로 순서를 바꾸면(한 바퀴 뒤 재셔플) 앱은 대기열을 다시 보내지 않고 따라간다', () async {
    cubit.playQueue(tracks);
    await settle();
    final calls = [...engine.calls];
    engine.emitQueueChange(
      PlaybackQueueChange(
        ids: [tracks[0].id, tracks[2].id, tracks[1].id],
        index: 0,
        shuffle: true,
        repeat: PlayerRepeatMode.off,
      ),
    );
    await settle();
    expect(cubit.state.queue.map((t) => t.id), [
      tracks[0].id,
      tracks[2].id,
      tracks[1].id,
    ]);
    expect(cubit.state.shuffle, isTrue);
    expect(engine.calls, calls);
  });

  test('모르는 곡이 든 대기열 이벤트는 건드리지 않는다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.emitQueueChange(
      const PlaybackQueueChange(
        ids: ['unknown', 'x'],
        index: 0,
        shuffle: false,
        repeat: PlayerRepeatMode.off,
      ),
    );
    await settle();
    expect(cubit.state.queue, tracks);
  });

  test('명령 결과가 대기열을 정한다: 엔진이 돌려준 순서를 그대로 비춘다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.moveInQueue(0, 2);
    await settle();
    expect(cubit.state.queue.map((t) => t.id), [
      tracks[1].id,
      tracks[2].id,
      tracks[0].id,
    ]);
    expect(cubit.state.index, 2);
    expect(cubit.state.track, tracks[0]);
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

    test('셔플 여부도 되살리고 끄는 것은 엔진에 맡긴다', () async {
      engine.restoreSnapshot = fromEngine(
        extras: jsonEncode({'shuffle': true}),
      );
      await cubit.restore((id) => tracks.where((t) => t.id == id).firstOrNull);
      expect(cubit.state.shuffle, isTrue);
      cubit.toggleShuffle();
      await settle();
      expect(engine.calls, contains('shuffle:false'));
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
