import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../library/domain/entities/track.dart';
import '../../domain/entities/player_repeat_mode.dart';

export '../../domain/entities/player_repeat_mode.dart';

class NowPlayingState extends Equatable {
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

  @override
  List<Object?> get props => [
    queue,
    index,
    isPlaying,
    position,
    shuffle,
    repeat,
  ];
}

/// 재생 상태. 처음에는 대기열이 비어 있다(미니 플레이어 숨김).
/// 지금은 화면 상태만 움직이고, 재생 엔진(just_audio + audio_service)이 붙으면 엔진을 부른다.
class NowPlayingCubit extends Cubit<NowPlayingState> {
  NowPlayingCubit()
    : super(
        const NowPlayingState(
          queue: [],
          index: 0,
          isPlaying: false,
          position: Duration.zero,
          shuffle: false,
          repeat: PlayerRepeatMode.off,
        ),
      );

  void togglePlay() => emit(state.copyWith(isPlaying: !state.isPlaying));

  void playQueue(List<Track> queue, {int index = 0}) {
    if (queue.isEmpty) return;
    emit(
      state.copyWith(
        queue: queue,
        index: index.clamp(0, queue.length - 1),
        position: Duration.zero,
        isPlaying: true,
      ),
    );
  }

  void next() {
    if (state.queue.isEmpty) return;
    final last = state.index == state.queue.length - 1;
    if (last && state.repeat == PlayerRepeatMode.off) return;
    emit(
      state.copyWith(
        index: last ? 0 : state.index + 1,
        position: Duration.zero,
      ),
    );
  }

  /// 3초 넘게 들었으면 처음으로, 아니면 이전 곡.
  void previous() {
    if (state.position > const Duration(seconds: 3) || state.index == 0) {
      emit(state.copyWith(position: Duration.zero));
      return;
    }
    emit(state.copyWith(index: state.index - 1, position: Duration.zero));
  }

  void seekFraction(double fraction) {
    final total = state.track?.duration;
    if (total == null) return;
    emit(state.copyWith(position: total * fraction.clamp(0.0, 1.0)));
  }

  void toggleShuffle() => emit(state.copyWith(shuffle: !state.shuffle));

  void cycleRepeat() => emit(
    state.copyWith(
      repeat: PlayerRepeatMode
          .values[(state.repeat.index + 1) % PlayerRepeatMode.values.length],
    ),
  );

  void jumpTo(int index) {
    if (index < 0 || index >= state.queue.length) return;
    emit(state.copyWith(index: index, position: Duration.zero));
  }
}
