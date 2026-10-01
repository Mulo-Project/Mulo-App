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

  /// 지금 곡 바로 뒤에 끼운다. 대기열이 비어 있으면 이 곡을 바로 재생한다.
  /// 이미 대기열에 있는 곡이면 그 자리를 옮긴다 (지금 재생 중인 곡이면 그대로).
  void playNext(Track track) {
    if (state.queue.isEmpty) return playQueue([track]);
    if (state.track == track) return;
    final current = state.track!;
    final rest = [...state.queue]..remove(track);
    final at = rest.indexOf(current) + 1;
    emit(
      state.copyWith(
        queue: [...rest.take(at), track, ...rest.skip(at)],
        index: at - 1,
      ),
    );
  }

  /// 대기열 맨 뒤에 붙인다. 대기열이 비어 있으면 이 곡을 바로 재생한다.
  /// 이미 대기열에 있는 곡이면 건너뛴다.
  void addToQueue(Track track) {
    if (state.queue.isEmpty) return playQueue([track]);
    if (state.queue.contains(track)) return;
    emit(state.copyWith(queue: [...state.queue, track]));
  }

  /// 곡 정보가 바뀌었을 때 대기열의 같은 곡을 새 정보로 바꾼다.
  void updateTrack(Track track) {
    if (!state.queue.contains(track)) return;
    emit(
      state.copyWith(
        queue: [for (final t in state.queue) t == track ? track : t],
      ),
    );
  }

  /// 곡이 보관함에서 지워졌을 때 대기열에서도 뺀다.
  /// 재생 중인 곡을 빼면 다음 곡(없으면 마지막 곡)으로 넘어가 처음부터 재생한다.
  void removeFromQueue(Track track) {
    final i = state.queue.indexOf(track);
    if (i < 0) return;
    final queue = [...state.queue]..removeAt(i);
    if (queue.isEmpty) {
      emit(state.copyWith(queue: queue, index: 0, isPlaying: false));
      return;
    }
    if (i < state.index) {
      emit(state.copyWith(queue: queue, index: state.index - 1));
    } else if (i > state.index) {
      emit(state.copyWith(queue: queue));
    } else {
      emit(
        state.copyWith(
          queue: queue,
          index: state.index.clamp(0, queue.length - 1),
          position: Duration.zero,
        ),
      );
    }
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

  /// [position]으로 옮긴다 (곡 길이 안으로 맞춘다).
  void seekTo(Duration position) {
    final total = state.track?.duration;
    if (total == null) return;
    emit(
      state.copyWith(
        position: position < Duration.zero
            ? Duration.zero
            : (position > total ? total : position),
      ),
    );
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
