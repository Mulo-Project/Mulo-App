import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/sample/sample_data.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';

void main() {
  late NowPlayingCubit cubit;
  NowPlayingCubit vm() => cubit;
  NowPlayingState state() => cubit.state;

  setUp(() {
    cubit = NowPlayingCubit()..playQueue(SampleData.tracks.take(3).toList());
  });
  tearDown(() => cubit.close());

  test('playQueue는 처음부터 재생한다', () {
    expect(state().index, 0);
    expect(state().position, Duration.zero);
    expect(state().isPlaying, isTrue);
  });

  test('togglePlay는 재생/일시정지를 바꾼다', () {
    vm().togglePlay();
    expect(state().isPlaying, isFalse);
  });

  test('반복 꺼짐이면 마지막 곡에서 next가 멈춘다', () {
    vm()
      ..next()
      ..next()
      ..next();
    expect(state().index, 2);
  });

  test('전체 반복이면 마지막 곡 다음은 첫 곡', () {
    vm()
      ..cycleRepeat()
      ..next()
      ..next()
      ..next();
    expect(state().repeat, PlayerRepeatMode.all);
    expect(state().index, 0);
  });

  test('previous: 3초 넘게 들었으면 처음으로, 아니면 이전 곡', () {
    vm()
      ..next()
      ..seekFraction(.5)
      ..previous();
    expect(state().index, 1);
    expect(state().position, Duration.zero);
    vm().previous();
    expect(state().index, 0);
  });

  test('cycleRepeat은 꺼짐 → 전체 → 한 곡 → 꺼짐', () {
    vm().cycleRepeat();
    vm().cycleRepeat();
    expect(state().repeat, PlayerRepeatMode.one);
    vm().cycleRepeat();
    expect(state().repeat, PlayerRepeatMode.off);
  });

  test('seekFraction은 0~1로 자른다', () {
    vm().seekFraction(2);
    expect(state().progress, 1);
  });

  group('곡 메뉴: 대기열 조작', () {
    final extra = SampleData.tracks[3];

    test('playNext는 지금 곡 바로 뒤에 끼우고 재생 위치는 그대로', () {
      vm().next();
      vm().playNext(extra);
      expect(state().queue.map((t) => t.id).toList().indexOf(extra.id), 2);
      expect(state().index, 1);
    });

    test('playNext: 이미 대기열에 있으면 자리를 옮긴다', () {
      final last = state().queue.last;
      vm().playNext(last);
      expect(state().queue.length, 3);
      expect(state().queue[1], last);
      expect(state().track, SampleData.tracks.first);
    });

    test('대기열이 비어 있으면 playNext · addToQueue는 바로 재생한다', () {
      final empty = NowPlayingCubit();
      addTearDown(empty.close);
      empty.addToQueue(extra);
      expect(empty.state.track, extra);
      expect(empty.state.isPlaying, isTrue);
    });

    test('addToQueue는 맨 뒤에 붙이고 중복은 건너뛴다', () {
      vm().addToQueue(extra);
      vm().addToQueue(extra);
      expect(state().queue.last, extra);
      expect(state().queue.length, 4);
    });

    test('removeFromQueue: 앞 곡을 빼면 재생 중인 곡이 그대로 유지된다', () {
      vm().next();
      final playing = state().track;
      vm().removeFromQueue(state().queue.first);
      expect(state().track, playing);
      expect(state().index, 0);
    });

    test('removeFromQueue: 재생 중인 곡을 빼면 다음 곡으로 넘어간다', () {
      final second = state().queue[1];
      vm().removeFromQueue(state().track!);
      expect(state().track, second);
      expect(state().position, Duration.zero);
    });

    test('removeFromQueue: 마지막 하나를 빼면 대기열이 비고 멈춘다', () {
      for (final t in [...state().queue]) {
        vm().removeFromQueue(t);
      }
      expect(state().queue, isEmpty);
      expect(state().isPlaying, isFalse);
    });
  });
}
