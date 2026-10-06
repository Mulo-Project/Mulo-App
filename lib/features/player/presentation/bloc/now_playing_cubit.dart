import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/player_repeat_mode.dart';
import '../../domain/usecases/audio_playback_usecases.dart';

export '../../domain/entities/player_repeat_mode.dart';

const Object _keep = Object();

class NowPlayingState extends Equatable {
  const NowPlayingState({
    required this.queue,
    required this.index,
    required this.isPlaying,
    required this.position,
    required this.shuffle,
    required this.repeat,
    this.sleepMinutes,
  });

  final List<Track> queue;
  final int index;
  final bool isPlaying;
  final Duration position;
  final bool shuffle;
  final PlayerRepeatMode repeat;

  /// 수면 타이머로 정한 분 (꺼져 있으면 null).
  final int? sleepMinutes;

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
    Object? sleepMinutes = _keep,
  }) => NowPlayingState(
    queue: queue ?? this.queue,
    index: index ?? this.index,
    isPlaying: isPlaying ?? this.isPlaying,
    position: position ?? this.position,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
    sleepMinutes: identical(sleepMinutes, _keep)
        ? this.sleepMinutes
        : sleepMinutes as int?,
  );

  @override
  List<Object?> get props => [
    queue,
    index,
    isPlaying,
    position,
    shuffle,
    repeat,
    sleepMinutes,
  ];
}

/// 재생 상태. 처음에는 대기열이 비어 있다(미니 플레이어 숨김).
/// [audio]가 있으면 상태가 바뀔 때 재생 엔진(just_audio)도 같이 움직이고, 엔진의 재생 위치 ·
/// 곡 끝 알림이 상태로 돌아온다. 없으면 화면 상태만 움직인다 (테스트).
class NowPlayingCubit extends Cubit<NowPlayingState> {
  NowPlayingCubit({AudioPlayback? audio, Random? random})
    : _audio = audio,
      _random = random ?? Random(),
      super(
        const NowPlayingState(
          queue: [],
          index: 0,
          isPlaying: false,
          position: Duration.zero,
          shuffle: false,
          repeat: PlayerRepeatMode.off,
        ),
      ) {
    if (audio == null) return;
    _subs = [
      audio.watchPosition(const NoParams()).listen(_onEnginePosition),
      audio.watchCompleted(const NoParams()).listen((_) => _onCompleted()),
    ];
  }

  final AudioPlayback? _audio;
  final Random _random;
  var _subs = <StreamSubscription<Object?>>[];

  /// 엔진 작업은 순서대로 하나씩 (곡을 불러오는 동안 재생 · 이동이 끼어들지 않게).
  Future<void> _tail = Future.value();

  /// 곡을 불러오는 중에는 엔진의 옛 재생 위치를 상태에 넣지 않는다.
  var _ready = false;

  /// 엔진이 알려 준 위치를 상태에 넣는 중 (이때는 엔진을 다시 움직이지 않는다).
  var _fromEngine = false;

  /// 시크바를 끄는 중: 위치는 화면 상태만 바꾸고, 엔진 이동은 손을 뗄 때 한 번만 한다.
  var _scrubbing = false;

  /// 셔플을 켜기 전 순서 (끄면 이 순서로 되돌린다).
  List<Track>? _original;

  void _run(Future<void> Function(AudioPlayback audio) job) {
    final audio = _audio;
    if (audio == null) return;
    _tail = _tail.then((_) => job(audio)).catchError((Object _) {});
  }

  @override
  void onChange(Change<NowPlayingState> change) {
    super.onChange(change);
    final from = change.currentState;
    final to = change.nextState;
    if (_audio == null || _fromEngine || _scrubbing) return;

    final track = to.track;
    if (track == null) {
      if (from.track != null || from.isPlaying != to.isPlaying) {
        _ready = false;
        _run((a) => a.pause(const NoParams()));
      }
      return;
    }
    if (track.uri != from.track?.uri) {
      _ready = false;
      _run((a) => _loadCurrent(a, track.uri));
    } else {
      if (from.position != to.position) _run((a) => a.seek(to.position));
      if (from.isPlaying != to.isPlaying) {
        _run(
          (a) => to.isPlaying
              ? a.play(const NoParams())
              : a.pause(const NoParams()),
        );
      }
    }
  }

  /// [uri]를 불러와 지금 상태가 재생 중이면 재생한다. 못 불러오면 멈춘다.
  Future<void> _loadCurrent(AudioPlayback a, String uri) async {
    if (state.track?.uri != uri) return; // 그새 다른 곡으로 바뀜: 그 곡의 작업이 따로 있다.
    try {
      if (uri.isEmpty) throw StateError('empty uri');
      await a.load(uri);
      if (state.track?.uri != uri) return;
      _ready = true;
      if (state.position > Duration.zero) await a.seek(state.position);
      if (state.isPlaying) await a.play(const NoParams());
    } on Object {
      if (!isClosed && state.track?.uri == uri) {
        emit(state.copyWith(isPlaying: false, position: Duration.zero));
      }
    }
  }

  void _onEnginePosition(Duration position) {
    if (!_ready || _scrubbing || position == state.position) return;
    _fromEngine = true;
    emit(state.copyWith(position: position));
    _fromEngine = false;
  }

  /// 곡 끝: 한 곡 반복이면 처음부터 다시, 아니면 다음 곡 (마지막 곡이면 반복 설정에 따라).
  void _onCompleted() {
    if (state.track == null) return;
    if (state.repeat == PlayerRepeatMode.one) {
      _run((a) async {
        await a.seek(Duration.zero);
        await a.play(const NoParams());
      });
      return;
    }
    final last = state.index == state.queue.length - 1;
    if (last && state.repeat == PlayerRepeatMode.off) {
      emit(state.copyWith(isPlaying: false, position: Duration.zero));
      return;
    }
    if (last && state.queue.length == 1) {
      // 같은 곡 하나뿐인 전체 반복: 곡은 그대로라 불러오지 않고 처음부터 다시.
      _run((a) async {
        await a.seek(Duration.zero);
        await a.play(const NoParams());
      });
      return;
    }
    next();
  }

  Timer? _sleep;

  /// [minutes]분 뒤에 재생을 멈춘다. null이면 타이머를 끈다.
  void setSleepTimer(int? minutes) {
    _sleep?.cancel();
    _sleep = null;
    if (minutes != null) {
      _sleep = Timer(Duration(minutes: minutes), () {
        _sleep = null;
        emit(state.copyWith(isPlaying: false, sleepMinutes: null));
      });
    }
    emit(state.copyWith(sleepMinutes: minutes));
  }

  @override
  Future<void> close() {
    _sleep?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    return super.close();
  }

  void togglePlay() => emit(state.copyWith(isPlaying: !state.isPlaying));

  void playQueue(List<Track> queue, {int index = 0}) {
    if (queue.isEmpty) return;
    final at = index.clamp(0, queue.length - 1);
    if (state.shuffle) {
      // 셔플 중이면 고른 곡을 맨 앞에 두고 나머지를 섞는다.
      _original = queue;
      emit(
        state.copyWith(
          queue: [queue[at], ..._shuffled(queue.where((t) => t != queue[at]))],
          index: 0,
          position: Duration.zero,
          isPlaying: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        queue: queue,
        index: at,
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
    if (last && state.shuffle && state.queue.length > 1) {
      // 셔플 중 한 바퀴를 다 돌았으면 순서를 새로 섞는다 (방금 들은 곡이 맨 앞에 오지 않게).
      emit(
        state.copyWith(
          queue: _shuffled(state.queue, avoidFirst: state.track),
          index: 0,
          position: Duration.zero,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        index: last ? 0 : state.index + 1,
        position: Duration.zero,
      ),
    );
  }

  /// 3초 넘게 들었으면 처음으로, 아니면 이전 곡 (첫 곡이면 마지막 곡).
  void previous() {
    if (state.position > const Duration(seconds: 3) || state.queue.length < 2) {
      emit(state.copyWith(position: Duration.zero));
      return;
    }
    if (state.index == 0) {
      emit(
        state.copyWith(index: state.queue.length - 1, position: Duration.zero),
      );
      return;
    }
    emit(state.copyWith(index: state.index - 1, position: Duration.zero));
  }

  /// 시크바 끌기 시작.
  void beginScrub() => _scrubbing = true;

  /// 시크바 끌기 끝: 지금 위치로 엔진을 한 번 옮긴다.
  void endScrub() {
    if (!_scrubbing) return;
    _scrubbing = false;
    final position = state.position;
    _run((a) => a.seek(position));
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

  /// [queue]를 처음부터 재생하되 셔플을 켠다.
  void playShuffled(List<Track> queue) {
    if (queue.isEmpty) return;
    playQueue(queue);
    if (!state.shuffle) toggleShuffle();
  }

  /// 셔플을 켜면 지금 곡을 맨 앞에 두고 나머지를 섞고, 끄면 켜기 전 순서로 되돌린다.
  void toggleShuffle() {
    final current = state.track;
    if (current == null) {
      emit(state.copyWith(shuffle: !state.shuffle));
      return;
    }
    if (!state.shuffle) {
      _original = state.queue;
      emit(
        state.copyWith(
          shuffle: true,
          queue: [
            current,
            ..._shuffled(state.queue.where((t) => t != current)),
          ],
          index: 0,
        ),
      );
      return;
    }
    final original = _original ?? state.queue;
    _original = null;
    final queue = [
      ...original.where(state.queue.contains),
      ...state.queue.where((t) => !original.contains(t)),
    ];
    emit(
      state.copyWith(
        shuffle: false,
        queue: queue,
        index: queue.indexOf(current),
      ),
    );
  }

  /// [source]를 섞은 새 목록. [avoidFirst]가 맨 앞에 오면 한 번 더 섞는다 (곡이 둘 이상일 때).
  List<Track> _shuffled(Iterable<Track> source, {Track? avoidFirst}) {
    final list = source.toList();
    if (list.length < 2) return list;
    list.shuffle(_random);
    if (avoidFirst != null && list.first == avoidFirst) {
      list.add(list.removeAt(0));
    }
    return list;
  }

  void cycleRepeat() => emit(
    state.copyWith(
      repeat: PlayerRepeatMode
          .values[(state.repeat.index + 1) % PlayerRepeatMode.values.length],
    ),
  );

  /// 대기열에서 [from] 곡을 [to] 자리로 옮긴다 ([to]는 옮긴 뒤의 자리).
  /// 재생 중인 곡은 그대로 이어서 재생한다.
  void moveInQueue(int from, int to) {
    final n = state.queue.length;
    if (from < 0 || from >= n || to < 0 || to >= n || from == to) return;
    final current = state.track!;
    final queue = [...state.queue];
    queue.insert(to, queue.removeAt(from));
    emit(state.copyWith(queue: queue, index: queue.indexOf(current)));
  }

  /// 지금 곡 뒤의 곡들을 무작위로 섞는다 (이미 들은 곡과 지금 곡은 그대로).
  void shuffleUpNext([Random? random]) {
    final upNext = state.queue.skip(state.index + 1).toList();
    if (upNext.length < 2) return;
    upNext.shuffle(random ?? _random);
    emit(
      state.copyWith(queue: [...state.queue.take(state.index + 1), ...upNext]),
    );
  }

  /// 대기열을 모두 비운다. 재생 중인 곡도 멈추고 지워진다 (미니 플레이어는 사라진다).
  void clearQueue() {
    if (state.queue.isEmpty) return;
    _original = null;
    emit(
      state.copyWith(
        queue: const [],
        index: 0,
        isPlaying: false,
        position: Duration.zero,
      ),
    );
  }

  void jumpTo(int index) {
    if (index < 0 || index >= state.queue.length) return;
    emit(state.copyWith(index: index, position: Duration.zero));
  }
}
