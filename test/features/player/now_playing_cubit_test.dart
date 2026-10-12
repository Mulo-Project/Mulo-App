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

  test('반복 꺼짐이어도 마지막 곡에서 next를 누르면 첫 곡으로 돌아간다', () {
    vm()
      ..next()
      ..next()
      ..next();
    expect(state().index, 0);
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

  test('첫 곡에서 previous는 마지막 곡으로', () {
    vm().previous();
    expect(state().index, 2);
    expect(state().position, Duration.zero);
  });

  group('셔플', () {
    final tracks = TestData.tracks.take(6).toList();
    setUp(() => cubit.playQueue(tracks));

    test('켜면 지금 곡은 맨 앞, 나머지는 섞이고 끄면 원래 순서', () {
      vm().toggleShuffle();
      expect(state().queue.first, tracks.first);
      expect(state().queue.toSet(), tracks.toSet());
      vm().toggleShuffle();
      expect(state().queue, tracks);
      expect(state().index, 0);
    });

    test('한 바퀴(전체 반복) 돌면 순서를 새로 섞는다', () {
      vm()
        ..cycleRepeat()
        ..toggleShuffle();
      final first = [...state().queue];
      for (var i = 0; i < first.length; i++) {
        vm().next();
      }
      expect(state().index, 0);
      expect(state().queue.toSet(), tracks.toSet());
      expect(state().queue.first, isNot(first.last));
    });
  });

  test('시크바를 끄는 동안 위치는 바뀌고 끝나면 정상 동작', () {
    vm()
      ..beginScrub()
      ..seekFraction(.5)
      ..endScrub();
    expect(state().progress, closeTo(.5, .001));
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

    test('shuffleQueue는 지금 곡을 맨 앞에 두고 나머지 전체(들은 곡 포함)를 섞는다', () {
      final big = TestData.tracks.take(8).toList();
      cubit.playQueue(big, index: 2);
      cubit.shuffleQueue(Random(42));
      expect(state().index, 0);
      expect(state().queue.first, big[2]);
      expect(state().queue.toSet(), big.toSet());
      expect(state().queue.length, big.length);
      expect(state().queue, isNot(big));
    });

    test('clearQueue는 재생 중인 곡까지 모두 비우고 멈춘다', () {
      vm().jumpTo(1);
      vm().clearQueue();
      expect(state().queue, isEmpty);
      expect(state().track, isNull);
      expect(state().isPlaying, isFalse);
    });
  });
}
