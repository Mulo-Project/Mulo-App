import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sample/sample_data.dart';
import '../../library/domain/track.dart';

enum PlayerRepeatMode { off, all, one }

@immutable
class NowPlayingState {
  const NowPlayingState({
    required this.queue,
    required this.index,
    required this.isPlaying,
    required this.position,
    required this.shuffle,
    required this.repeat,
  });

  final List<Track> queue;
  final int index;
  final bool isPlaying;
  final Duration position;
  final bool shuffle;
  final PlayerRepeatMode repeat;

  Track? get track => queue.isEmpty ? null : queue[index];

  double get progress {
    final total = track?.duration.inMilliseconds ?? 0;
    return total == 0 ? 0 : position.inMilliseconds / total;
  }

  NowPlayingState copyWith({
    List<Track>? queue,
    int? index,
    bool? isPlaying,
    Duration? position,
    bool? shuffle,
    PlayerRepeatMode? repeat,
  }) => NowPlayingState(
    queue: queue ?? this.queue,
    index: index ?? this.index,
    isPlaying: isPlaying ?? this.isPlaying,
    position: position ?? this.position,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
  );
}

/// 재생 상태 ViewModel. 지금은 자리 표시 데이터로 화면만 움직이고,
/// 재생 엔진(just_audio + audio_service)이 붙으면 이 클래스가 엔진을 부른다.
class NowPlayingViewModel extends Notifier<NowPlayingState> {
  @override
  NowPlayingState build() => NowPlayingState(
    queue: SampleData.tracks.take(6).toList(),
    index: 0,
    isPlaying: true,
    position: const Duration(minutes: 1, seconds: 42),
    shuffle: false,
    repeat: PlayerRepeatMode.off,
  );

  void togglePlay() => state = state.copyWith(isPlaying: !state.isPlaying);

  void playQueue(List<Track> queue, {int index = 0}) {
    if (queue.isEmpty) return;
    state = state.copyWith(
      queue: queue,
      index: index.clamp(0, queue.length - 1),
      position: Duration.zero,
      isPlaying: true,
    );
  }

  void next() {
    if (state.queue.isEmpty) return;
    final last = state.index == state.queue.length - 1;
    if (last && state.repeat == PlayerRepeatMode.off) return;
    state = state.copyWith(
      index: last ? 0 : state.index + 1,
      position: Duration.zero,
    );
  }

  /// 3초 넘게 들었으면 처음으로, 아니면 이전 곡.
  void previous() {
    if (state.position > const Duration(seconds: 3) || state.index == 0) {
      state = state.copyWith(position: Duration.zero);
      return;
    }
    state = state.copyWith(index: state.index - 1, position: Duration.zero);
  }

  void seekFraction(double fraction) {
    final total = state.track?.duration;
    if (total == null) return;
    state = state.copyWith(position: total * fraction.clamp(0.0, 1.0));
  }

  void toggleShuffle() => state = state.copyWith(shuffle: !state.shuffle);

  void cycleRepeat() => state = state.copyWith(
    repeat: PlayerRepeatMode
        .values[(state.repeat.index + 1) % PlayerRepeatMode.values.length],
  );

  void jumpTo(int index) {
    if (index < 0 || index >= state.queue.length) return;
    state = state.copyWith(index: index, position: Duration.zero);
  }
}

final nowPlayingProvider =
    NotifierProvider<NowPlayingViewModel, NowPlayingState>(
      NowPlayingViewModel.new,
    );
