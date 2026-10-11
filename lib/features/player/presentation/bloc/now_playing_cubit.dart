import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/playback_snapshot.dart';
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
/// [audio]가 있으면 대기열이 바뀔 때마다 스냅샷(순서가 정해진 목록 · 현재 위치 · 반복)을 엔진에 보내고,
/// 곡 넘김은 엔진이 한다. 엔진의 재생 위치 · 곡 넘김 · 끝 알림이 상태로 돌아온다.
/// 없으면 화면 상태만 움직인다 (테스트).
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
      audio.watchTrackChange(const NoParams()).listen(_onEngineTrack),
      audio.watchEnded(const NoParams()).listen((_) => _onEnded()),
      audio.watchPlaying(const NoParams()).listen(_onEnginePlaying),
    ];
  }

  final AudioPlayback? _audio;
  final Random _random;
  var _subs = <StreamSubscription<Object?>>[];

  /// 엔진 작업은 순서대로 하나씩 (곡을 불러오는 동안 재생 · 이동이 끼어들지 않게).
  Future<void> _tail = Future.value();

  /// 곡을 불러오는 중에는 엔진의 옛 재생 위치를 상태에 넣지 않는다.
  var _ready = false;

  /// 엔진이 알려 준 것을 상태에 넣는 중 (이때는 엔진을 다시 움직이지 않는다).
  var _fromEngine = false;

  /// 시크바를 끄는 중: 위치는 화면 상태만 바꾸고, 엔진 이동은 손을 뗄 때 한 번만 한다.
  var _scrubbing = false;

  /// 셔플을 켜기 전 순서 (끄면 이 순서로 되돌린다).
  List<Track>? _original;

  /// 아직 끝나지 않은 엔진 작업 수. 작업 중에 오는 재생 · 곡 넘김 신호는 우리가 시킨 것이라 상태에 넣지 않는다.
  var _pending = 0;

  /// 엔진이 지금 쥐고 있다고 보는 대기열 (목록 · 반복 · extras만 비교한다).
  var _pushed = const PlaybackSnapshot(items: [], index: 0, playing: false);

  /// 앱이 켜져 있는 중에 알림을 눌러 플레이어 화면을 열라는 요청.
  Stream<void> get openPlayerRequests =>
      _audio?.watchOpenPlayer(const NoParams()) ?? const Stream.empty();

  /// 알림을 눌러 앱이 새로 켜졌는지 한 번 알려 주고 비운다.
  Future<bool> takeOpenPlayerRequest() async =>
      await _audio?.takeOpenPlayerRequest(const NoParams()) ?? false;

  void _run(Future<void> Function(AudioPlayback audio) job) {
    final audio = _audio;
    if (audio == null) return;
    _pending++;
    _tail = _tail
        .then((_) => job(audio))
        .catchError((Object _) {})
        .whenComplete(() => _pending--);
  }

  /// 엔진이 재생 · 정지를 알려 왔을 때: 다른 앱에 오디오 포커스를 뺏겨 멈췄거나(전화, 영상)
  /// 돌려받아 다시 시작한 것을 재생 상태에 맞춘다. 우리가 시킨 작업 중의 신호는 무시한다.
  void _onEnginePlaying(bool playing) {
    if (isClosed ||
        !_ready ||
        _pending > 0 ||
        _scrubbing ||
        state.track == null ||
        state.isPlaying == playing) {
      return;
    }
    _fromEngine = true;
    emit(state.copyWith(isPlaying: playing));
    _fromEngine = false;
  }

  PlaybackSnapshot _snapshotOf(NowPlayingState s, {Duration? position}) =>
      PlaybackSnapshot(
        items: [
          for (final t in s.queue)
            PlaybackItem(
              id: t.id,
              uri: t.uri,
              title: t.title,
              artist: t.artist,
              album: t.album,
              duration: t.duration,
            ),
        ],
        index: s.index,
        playing: s.isPlaying,
        repeat: s.repeat,
        position: position,
        extras: jsonEncode({
          'shuffle': s.shuffle,
          if (_original != null) 'original': [for (final t in _original!) t.id],
        }),
      );

  /// 엔진에 보낸 것과 목록 · 반복 · extras가 같은지 (현재 곡 · 재생 · 위치는 따로 다룬다).
  bool _sameQueue(PlaybackSnapshot a, PlaybackSnapshot b) =>
      a.repeat == b.repeat &&
      a.extras == b.extras &&
      a.items.length == b.items.length &&
      Iterable<int>.generate(a.items.length)
          .every((i) => a.items[i] == b.items[i]);

  @override
  void onChange(Change<NowPlayingState> change) {
    super.onChange(change);
    final from = change.currentState;
    final to = change.nextState;
    if (_audio == null || _fromEngine || _scrubbing) return;

    final track = to.track;
    if (track == null) {
      if (_pushed.items.isNotEmpty || from.isPlaying) {
        _ready = false;
        _pushed = const PlaybackSnapshot(items: [], index: 0, playing: false);
        final empty = _pushed;
        _run((a) => a.setQueue(empty));
      }
      return;
    }

    final desired = _snapshotOf(to);
    if (!_sameQueue(desired, _pushed)) {
      // 같은 곡을 계속 듣는 중에 뒤의 목록만 바뀌면 재생 위치를 건드리지 않는다.
      final keep = from.track == track && from.position == to.position;
      if (!keep) _ready = false;
      _pushed = desired;
      final snapshot = _snapshotOf(to, position: keep ? null : to.position);
      _run((a) => _push(a, snapshot));
      return;
    }
    if (from.index != to.index || from.track != track) {
      _ready = false;
      final index = to.index;
      final position = to.position;
      _run((a) async {
        if (state.index != index) return; // 그새 다른 곡으로 바뀜: 그 작업이 따로 있다.
        final current = state.track;
        try {
          if (current == null || current.uri.isEmpty) {
            throw StateError('empty uri');
          }
          await a.skipTo(index);
          if (position > Duration.zero) await a.seek(position);
        } on Object {
          if (!isClosed && state.index == index) {
            emit(state.copyWith(isPlaying: false, position: Duration.zero));
          }
          return;
        }
        if (state.index != index) return;
        _ready = true;
        await (state.isPlaying
            ? a.play(const NoParams())
            : a.pause(const NoParams()));
      });
      return;
    }
    if (from.position != to.position) _run((a) => a.seek(to.position));
    if (from.isPlaying != to.isPlaying) {
      _run(
        (a) =>
            to.isPlaying ? a.play(const NoParams()) : a.pause(const NoParams()),
      );
    }
  }

  /// [snapshot]을 엔진에 보낸다. 현재 곡을 못 불러오면 멈춘다.
  Future<void> _push(AudioPlayback a, PlaybackSnapshot snapshot) async {
    final current = snapshot.current;
    if (current == null || state.track?.id != current.id) return; // 그새 바뀜
    try {
      if (current.uri.isEmpty) throw StateError('empty uri');
      await a.setQueue(snapshot);
      if (state.track?.id != current.id) return;
      _ready = true;
    } on Object {
      if (!isClosed && state.track?.id == current.id) {
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

  /// 엔진이 스스로 곡을 넘겼다 (곡 끝, 알림 · 이어폰의 이전 · 다음).
  void _onEngineTrack(PlaybackTrackChange change) {
    if (isClosed || _pending > 0 || _scrubbing) return;
    final queue = state.queue;
    if (change.index < 0 ||
        change.index >= queue.length ||
        queue[change.index].id != change.id ||
        change.index == state.index) {
      return;
    }
    final wrapped =
        state.index == queue.length - 1 &&
        change.index == 0 &&
        queue.length > 1;
    final heard = state.track;
    _ready = true;
    _fromEngine = true;
    emit(state.copyWith(index: change.index, position: Duration.zero));
    _fromEngine = false;
    if (wrapped && state.shuffle && heard != null) {
      // 셔플 중 한 바퀴를 다 돌았으면 순서를 새로 섞는다 (방금 들은 곡이 바로 뒤에 오지 않게).
      final current = state.track!;
      final rest = _shuffled(
        state.queue.where((t) => t != current),
        avoidFirst: heard,
      );
      emit(state.copyWith(queue: [current, ...rest], index: 0));
    }
  }

  /// 대기열 끝까지 들었다 (반복 없음): 마지막 곡에서 멈춘다.
  void _onEnded() {
    if (isClosed || state.track == null) return;
    _fromEngine = true;
    emit(state.copyWith(isPlaying: false, position: Duration.zero));
    _fromEngine = false;
  }

  /// 앱을 다시 켰을 때 엔진이 쥐고 있는 대기열을 상태로 되살린다 (이미 곡이 있으면 하지 않는다).
  /// [find]는 id로 보관함의 곡을 찾는다. 보관함에서 사라진 곡은 건너뛴다.
  Future<void> restore(Track? Function(String id) find) async {
    final audio = _audio;
    if (audio == null || state.queue.isNotEmpty) return;
    final snapshot = await audio.restore(const NoParams());
    if (snapshot == null || isClosed || state.queue.isNotEmpty) return;
    final queue = <Track>[];
    var index = 0;
    for (var i = 0; i < snapshot.items.length; i++) {
      final track = find(snapshot.items[i].id);
      if (track == null) continue;
      if (i <= snapshot.index) index = queue.length;
      queue.add(track);
    }
    if (queue.isEmpty) return;
    var shuffle = false;
    List<Track>? original;
    try {
      final extras = jsonDecode(snapshot.extras);
      if (extras is Map) {
        shuffle = extras['shuffle'] == true;
        final ids = extras['original'];
        if (ids is List) {
          original = [for (final id in ids) ?find('$id')];
        }
      }
    } on Object {
      // extras가 없거나 깨졌으면 셔플 정보 없이 복원한다.
    }
    _original = original;
    final dropped = queue.length != snapshot.items.length;
    final moved = dropped && snapshot.current?.id != queue[index].id;
    _ready = true;
    _fromEngine = true;
    emit(
      NowPlayingState(
        queue: queue,
        index: index,
        isPlaying: snapshot.playing,
        position: snapshot.position ?? Duration.zero,
        shuffle: shuffle,
        repeat: snapshot.repeat,
      ),
    );
    _fromEngine = false;
    _pushed = _snapshotOf(state);
    // 보관함에서 사라진 곡이 있으면 엔진의 대기열도 맞춘다.
    if (dropped) {
      final snap = _snapshotOf(state, position: moved ? Duration.zero : null);
      _run((a) => _push(a, snap));
    }
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
    // 첫 곡이 아니라 무작위 곡에서 시작한다 (아니면 늘 목록 맨 위 곡이 먼저 나온다).
    playQueue(queue, index: _random.nextInt(queue.length));
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
