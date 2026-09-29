import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/sample/sample_data.dart';
import 'package:music_download_play_app/features/player/presentation/now_playing_view_model.dart';

void main() {
  late ProviderContainer container;
  NowPlayingViewModel vm() => container.read(nowPlayingProvider.notifier);
  NowPlayingState state() => container.read(nowPlayingProvider);

  setUp(() {
    container = ProviderContainer();
    vm().playQueue(SampleData.tracks.take(3).toList());
  });
  tearDown(() => container.dispose());

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
}
