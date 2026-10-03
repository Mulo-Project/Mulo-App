import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';

void main() {
  late NowPlayingCubit cubit;
  NowPlayingCubit vm() => cubit;
  NowPlayingState state() => cubit.state;

  setUp(() {
    cubit = NowPlayingCubit()..playQueue(TestData.tracks.take(3).toList());
  });
  tearDown(() => cubit.close());

  test('playQueue는 처음부터 재생한다', () {
    expect(state().index, 0);
    expect(state().position, Duration.zero);
    expect(state().isPlaying, isTrue);
  });

  test('playShuffled는 처음부터 재생하고 셔플을 켠다', () {
    vm().playShuffled(TestData.tracks.take(2).toList());
    expect(state().shuffle, isTrue);
    expect(state().index, 0);
    expect(state().queue.length, 2);
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
    final extra = TestData.tracks[3];

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
      expect(state().track, TestData.tracks.first);
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

  group('대기열 편집', () {
    test('moveInQueue는 곡 순서를 바꾸고 재생 중인 곡은 그대로 이어 간다', () {
      final queue = [...state().queue];
      vm().jumpTo(1); // 둘째 곡 재생 중
      vm().moveInQueue(0, 2);
      expect(state().queue, [queue[1], queue[2], queue[0]]);
      expect(state().track, queue[1]);
      expect(state().index, 0);

      vm().moveInQueue(2, 0);
      expect(state().queue, [queue[0], queue[1], queue[2]]);
      expect(state().track, queue[1]);
      expect(state().index, 1);
    });

    test('moveInQueue는 범위를 벗어나거나 제자리면 무시한다', () {
      final before = state().queue;
      vm()
        ..moveInQueue(1, 1)
        ..moveInQueue(-1, 0)
        ..moveInQueue(0, 3);
      expect(state().queue, before);
    });

    test('shuffleUpNext는 지금 곡과 앞의 곡은 두고 뒤의 곡만 섞는다', () {
      final big = TestData.tracks.take(8).toList();
      cubit.playQueue(big, index: 2);
      cubit.shuffleUpNext(Random(42));
      expect(state().queue.take(3).toList(), big.take(3).toList());
      expect(state().queue.skip(3).toSet(), big.skip(3).toSet());
      expect(state().queue.skip(3).toList(), isNot(big.skip(3).toList()));
      expect(state().index, 2);
    });

    test('clearQueue는 지금 재생 중인 곡만 남긴다', () {
      vm().jumpTo(1);
      final current = state().track;
      vm().clearQueue();
      expect(state().queue, [current]);
      expect(state().index, 0);
      expect(state().isPlaying, isTrue);
    });
  });
}
