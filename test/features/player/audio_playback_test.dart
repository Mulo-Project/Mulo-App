import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/player/domain/usecases/audio_playback_usecases.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

/// 재생 상태 Cubit과 재생 엔진 연결 (가짜 엔진).
void main() {
  late FakeAudioPlayer engine;
  late NowPlayingCubit cubit;
  final tracks = TestData.tracks.take(3).toList();

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    engine = FakeAudioPlayer();
    cubit = NowPlayingCubit(
      audio: AudioPlayback(
        watchPosition: WatchAudioPosition(engine),
        watchCompleted: WatchAudioCompleted(engine),
        watchPlaying: WatchAudioPlaying(engine),
        load: LoadAudio(engine),
        play: PlayAudio(engine),
        pause: PauseAudio(engine),
        seek: SeekAudio(engine),
      ),
    );
  });
  tearDown(() => cubit.close());

  test('곡을 고르면 불러와서 재생한다', () async {
    cubit.playQueue(tracks);
    await settle();
    expect(engine.calls, ['load:${tracks[0].uri}', 'play']);
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

  test('다음 곡 · 이전 곡은 새 곡을 불러온다', () async {
    cubit.playQueue(tracks);
    await settle();
    cubit.next();
    await settle();
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

  test('곡이 끝나면 다음 곡으로 넘어간다', () async {
    cubit.playQueue(tracks);
    await settle();
    engine.complete();
    await settle();
    expect(cubit.state.index, 1);
    expect(engine.loaded, tracks[1].uri);
  });

  test('마지막 곡이 끝나면 반복이 꺼져 있을 때 멈춘다', () async {
    cubit.playQueue(tracks, index: 2);
    await settle();
    engine.complete();
    await settle();
    expect(cubit.state.isPlaying, isFalse);
    expect(cubit.state.index, 2);
    expect(engine.playing, isFalse);
  });

  test('전체 반복이면 마지막 곡 뒤에 처음 곡으로 돌아간다', () async {
    cubit.cycleRepeat(); // all
    cubit.playQueue(tracks, index: 2);
    await settle();
    engine.complete();
    await settle();
    expect(cubit.state.index, 0);
    expect(engine.loaded, tracks[0].uri);
  });

  test('한 곡 반복이면 같은 곡을 처음부터 다시 재생한다', () async {
    cubit
      ..cycleRepeat()
      ..cycleRepeat(); // one
    cubit.playQueue(tracks);
    await settle();
    engine.calls.clear();
    engine.complete();
    await settle();
    expect(cubit.state.index, 0);
    expect(engine.calls, ['seek:0', 'play']);
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
    expect(engine.calls.where((c) => c.startsWith('load')), isEmpty);
  });

  test('불러오는 동안 온 옛 재생 위치는 무시한다', () async {
    cubit.playQueue(tracks);
    engine.emitPosition(const Duration(seconds: 99));
    await settle();
    expect(cubit.state.position, isNot(const Duration(seconds: 99)));
  });
}
