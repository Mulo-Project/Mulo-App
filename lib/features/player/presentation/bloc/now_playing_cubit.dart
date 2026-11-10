import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
    this.sleepEndsAt,
    this.loopStart,
    this.loopEnd,
  });

  final List<Track> queue;
  final int index;
  final bool isPlaying;
  final Duration position;
  final bool shuffle;
  final PlayerRepeatMode repeat;

  /// 수면 타이머로 정한 분 (꺼져 있으면 null).
  final int? sleepMinutes;

  /// 수면 타이머가 재생을 멈출 시각 (꺼져 있으면 null).
  final DateTime? sleepEndsAt;

  /// 구간 반복의 시작 · 끝 (현재 곡 안). 시작만 있으면 끝을 정하는 중이고, 둘 다 있으면 그 구간만 반복한다.
  final Duration? loopStart;
  final Duration? loopEnd;

  /// 구간 반복이 걸려 있는지 (시작과 끝이 모두 정해짐).
  bool get looping => loopStart != null && loopEnd != null;

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
    Object? sleepEndsAt = _keep,
    Object? loopStart = _keep,
    Object? loopEnd = _keep,
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
    sleepEndsAt: identical(sleepEndsAt, _keep)
        ? this.sleepEndsAt
        : sleepEndsAt as DateTime?,
    loopStart: identical(loopStart, _keep)
        ? this.loopStart
        : loopStart as Duration?,
    loopEnd: identical(loopEnd, _keep) ? this.loopEnd : loopEnd as Duration?,
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
    sleepEndsAt,
    loopStart,
    loopEnd,
  ];
}

/// 재생 상태. 처음에는 대기열이 비어 있다(미니 플레이어 숨김).
/// [audio]가 있으면 엔진이 대기열 순서 · 셔플 · 반복 · 곡 넘김의 원본을 쥔다: 앱은 명령(`setShuffle` · `setRepeat` ·
/// `playNext` · `addToQueue` · `removeFromQueue` · `moveInQueue`)을 보내고, 명령 결과와 `watchQueue` 이벤트로 온
/// 대기열 모습 · 재생 위치 · 곡 넘김 · 끝을 비추기만 한다 (편집 결과를 앱이 먼저 계산하지 않는다).
/// [audio]가 없으면 화면 상태만 움직이고 편집 · 셔플은 앱이 직접 계산한다 (테스트).
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
      audio.watchQueue(const NoParams()).listen(_onEngineQueue),
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

  /// 셔플을 켜기 전 순서 (끄면 이 순서로 되돌린다). 엔진이 없을 때만 쓴다 — 엔진이 있으면 엔진이 쥔다.
  List<Track>? _original;

  /// 엔진에 보낸 곡 (아직 화면 대기열에 없는 것 포함). 엔진이 돌려준 곡 id를 곡으로 바꾸는 데 쓴다.
  final _tracks = <String, Track>{};

  /// 다음에 엔진에 보내는 대기열을 셔플로 시작하게 한다 (섞는 일은 엔진이 한다).
  var _shuffleNew = false;

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
        .catchError((Object e) {
          debugPrint('MuloPlayback engine job failed: $e');
        })
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

  PlaybackSnapshot _snapshotOf(
    NowPlayingState s, {
    Duration? position,
    bool shuffleNew = false,
  }) => PlaybackSnapshot(
    items: [
      for (final t in s.queue)
        PlaybackItem(
          id: t.id,
          uri: t.uri,
          title: t.title,
          artist: t.artist,
          album: t.album,
          duration: t.duration,
          videoUri: t.videoUri,
        ),
    ],
    index: s.index,
    playing: s.isPlaying,
    repeat: s.repeat,
    position: position,
    shuffleNew: shuffleNew,
  );

  /// 엔진이 알려 준 것을 상태에 넣는다 (엔진을 다시 움직이지 않고, 보낸 것으로 친다).
  void _emitFromEngine(NowPlayingState next) {
    _fromEngine = true;
    emit(next);
    _fromEngine = false;
    _pushed = _snapshotOf(state);
  }

  /// 엔진이 스스로 대기열 순서 · 셔플 · 반복을 바꿨다 (한 바퀴 뒤 재셔플, 알림 셔플 버튼).
  /// 우리가 보낸 명령이 도는 중이면 그 결과가 더 나중 상태이므로 무시한다.
  void _onEngineQueue(PlaybackQueueChange change) {
    if (_pending > 0) return;
    _applyQueue(change);
  }

  /// 엔진이 알려 준 대기열 모습(명령 결과 · 이벤트)을 그대로 상태에 비춘다. 엔진을 다시 움직이지 않는다.
  /// 모르는 곡 id가 있으면 건드리지 않는다. 대기열이 비면 앱이 직접 비우므로 여기서는 두지 않는다.
  void _applyQueue(PlaybackQueueChange change) {
    if (isClosed || change.ids.isEmpty) return;
    final byId = {..._tracks, for (final t in state.queue) t.id: t};
    final queue = <Track>[];
    for (final id in change.ids) {
      final track = byId[id];
      if (track == null) {
        debugPrint('MuloPlayback queue ignored: unknown track $id');
        return;
      }
      queue.add(track);
    }
    _tracks
      ..clear()
      ..addEntries([for (final t in queue) MapEntry(t.id, t)]);
    final shown = state.track;
    var index = change.index.clamp(0, queue.length - 1);
    // 뒤에 이어질 명령이 있으면 화면의 현재 곡을 따라간다 (그 명령이 끝나면 엔진이 그 곡으로 온다).
    if (_pending > 1 && shown != null && queue.contains(shown)) {
      index = queue.indexOf(shown);
    }
    _emitFromEngine(
      state.copyWith(
        queue: queue,
        index: index,
        shuffle: change.shuffle,
        repeat: change.repeat,
        // 지금 곡이 바뀌었으면(듣던 곡을 뺌) 처음부터.
        position: shown?.id == queue[index].id ? null : Duration.zero,
      ),
    );
  }

  /// 대기열을 바꾸는 명령을 엔진에 보내고, 돌려받은 대기열 모습을 상태에 비춘다.
  void _command(Future<PlaybackQueueChange?> Function(AudioPlayback a) send) {
    _run((a) async {
      final result = await send(a);
      if (result != null) _applyQueue(result);
    });
  }

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
    if (_audio != null &&
        to.track != null &&
        (from.loopStart != to.loopStart || from.loopEnd != to.loopEnd)) {
      final start = to.looping ? to.loopStart : null;
      final end = to.looping ? to.loopEnd : null;
      _run((a) => a.setLoop((start: start, end: end)));
    }
    if (_audio == null || _fromEngine || _scrubbing) return;
    final shuffleNew = _shuffleNew;
    _shuffleNew = false;

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
    if (shuffleNew || !_sameQueue(desired, _pushed)) {
      // 같은 곡을 계속 듣는 중에 뒤의 목록만 바뀌면 재생 위치를 건드리지 않는다.
      final keep = from.track == track && from.position == to.position;
      if (!keep) _ready = false;
      _pushed = desired;
      final snapshot = _snapshotOf(
        to,
        position: keep ? null : to.position,
        shuffleNew: shuffleNew,
      );
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
        } on Object catch (e) {
          debugPrint('MuloPlayback skipTo failed: $e (index=$index)');
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
      final result = await a.setQueue(snapshot);
      if (state.track?.id != current.id) return;
      _ready = true;
      if (result != null) _applyQueue(result);
    } on Object catch (e) {
      debugPrint('MuloPlayback setQueue failed: $e (track=${current.id})');
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
    // 셔플 중 한 바퀴를 돌면 엔진이 순서를 새로 섞고 `queue` 이벤트로 알린다.
    _ready = true;
    _fromEngine = true;
    emit(state.copyWith(index: change.index, position: Duration.zero));
    _fromEngine = false;
  }

  /// 대기열 끝까지 들었다 (반복 없음): 엔진이 첫 곡으로 돌아가 멈춘 것과 같게 첫 곡에서 멈춘다.
  void _onEnded() {
    if (isClosed || state.track == null) return;
    _fromEngine = true;
    emit(
      state.copyWith(
        index: 0,
        isPlaying: false,
        position: Duration.zero,
        loopStart: null,
        loopEnd: null,
      ),
    );
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
      final item = snapshot.items[i];
      // 임시 저장한 음원은 보관함 곡이 아니라서 엔진이 쥔 정보(주소 · 제목)로 되살린다.
      final track =
          find(item.id) ??
          (item.id.startsWith(Track.savedIdPrefix)
              ? Track(
                  id: item.id,
                  title: item.title,
                  artist: item.artist,
                  album: item.album,
                  duration: item.duration,
                  addedAt: DateTime.fromMillisecondsSinceEpoch(0),
                  uri: item.uri,
                  source: TrackSource.saved,
                )
              : null);
      if (track == null) continue;
      if (i <= snapshot.index) index = queue.length;
      queue.add(track);
    }
    if (queue.isEmpty) return;
    var shuffle = false;
    try {
      final extras = jsonDecode(snapshot.extras);
      if (extras is Map) shuffle = extras['shuffle'] == true;
    } on Object {
      // extras가 없거나 깨졌으면 셔플 정보 없이 복원한다.
    }
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

  /// 곡이 바뀌면 구간 반복은 풀린다 (엔진도 곡이 바뀌면 스스로 푼다).
  @override
  void emit(NowPlayingState state) {
    final switched = state.track?.id != this.state.track?.id;
    super.emit(
      switched && (state.loopStart != null || state.loopEnd != null)
          ? state.copyWith(loopStart: null, loopEnd: null)
          : state,
    );
  }

  /// 구간 반복 지정을 한 단계 진행한다: 없음 → 첫 지점 → 두 번째 지점(반복 시작) → 해제.
  /// 두 번째 지점이 첫 지점보다 앞이어도 된다. 더 앞쪽이 시작, 뒤쪽이 끝이 된다.
  /// 두 지점이 1초 안이면 무시한다.
  void cycleLoop() {
    final track = state.track;
    if (track == null) return;
    if (state.looping) {
      emit(state.copyWith(loopStart: null, loopEnd: null));
    } else if (state.loopStart == null) {
      emit(state.copyWith(loopStart: state.position, loopEnd: null));
    } else {
      final first = state.loopStart!;
      final second = state.position;
      if ((second - first).abs() < const Duration(seconds: 1)) return;
      emit(
        second > first
            ? state.copyWith(loopEnd: second)
            : state.copyWith(loopStart: second, loopEnd: first),
      );
    }
  }

  /// 구간 반복 지정을 지운다.
  void clearLoop() {
    if (state.loopStart == null && state.loopEnd == null) return;
    emit(state.copyWith(loopStart: null, loopEnd: null));
  }

  Timer? _sleep;

  /// [minutes]분 뒤에 재생을 멈춘다. null이면 타이머를 끈다.
  void setSleepTimer(int? minutes) {
    _sleep?.cancel();
    _sleep = null;
    if (minutes != null) {
      _sleep = Timer(Duration(minutes: minutes), () {
        _sleep = null;
        emit(
          state.copyWith(
            isPlaying: false,
            sleepMinutes: null,
            sleepEndsAt: null,
          ),
        );
      });
    }
    emit(
      state.copyWith(
        sleepMinutes: minutes,
        sleepEndsAt: minutes == null
            ? null
            : DateTime.now().add(Duration(minutes: minutes)),
      ),
    );
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
    if (_audio != null) {
      // 엔진이 있으면 섞는 일은 엔진이 한다: 섞기 전 순서로 보내고 셔플로 시작하게 한다.
      _startQueue(queue, at, shuffle: state.shuffle);
      return;
    }
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

  PlaybackItem _itemOf(Track t) => PlaybackItem(
    id: t.id,
    uri: t.uri,
    title: t.title,
    artist: t.artist,
    album: t.album,
    duration: t.duration,
    videoUri: t.videoUri,
  );

  /// [queue]의 [at]번 곡부터 재생을 시작한다. [shuffle]이면 엔진이 그 곡을 맨 앞에 두고 나머지를 섞는다.
  void _startQueue(List<Track> queue, int at, {required bool shuffle}) {
    _shuffleNew = shuffle;
    emit(
      state.copyWith(
        queue: queue,
        index: at,
        position: Duration.zero,
        isPlaying: true,
        shuffle: shuffle,
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
    if (_audio != null) {
      _tracks[track.id] = track;
      _command((a) => a.playNext(_itemOf(track)));
      return;
    }
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
    if (_audio != null) {
      _tracks[track.id] = track;
      _command((a) => a.addToQueue(_itemOf(track)));
      return;
    }
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

  /// 보관함에서 사라진 곡들([ids])을 대기열에서 뺀다 (재생 중인 곡이면 다음 곡으로 넘어간다).
  void removeFromQueueByIds(Set<String> ids) {
    if (ids.isEmpty) return;
    for (final t in [...state.queue]) {
      if (ids.contains(t.id)) removeFromQueue(t);
    }
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
    if (_audio != null) {
      _command((a) => a.removeFromQueue(track.id));
      return;
    }
    emit(
      i < state.index
          ? state.copyWith(queue: queue, index: state.index - 1)
          : i > state.index
          ? state.copyWith(queue: queue)
          : state.copyWith(
              queue: queue,
              index: state.index.clamp(0, queue.length - 1),
              position: Duration.zero,
            ),
    );
  }

  /// 다음 곡. 마지막 곡이면 반복 설정과 상관없이 처음으로 돌아간다 (곡 끝에서 저절로 넘어갈 때만 반복을 따른다).
  void next() {
    if (state.queue.isEmpty) return;
    final last = state.index == state.queue.length - 1;
    // 엔진이 있으면 셔플 한 바퀴를 돌아 처음으로 갈 때 엔진이 순서를 새로 섞는다.
    if (_audio == null && last && state.shuffle && state.queue.length > 1) {
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
    final start = _random.nextInt(queue.length);
    if (_audio != null) {
      _startQueue(queue, start, shuffle: true);
      return;
    }
    playQueue(queue, index: start);
    // 막 시작한 재생이라 지금 곡을 맨 앞에 두어야 나머지 곡이 모두 이번 바퀴에 나온다.
    if (!state.shuffle) toggleShuffle(currentFirst: true);
  }

  /// 셔플을 켜면 지금 곡을 포함해 대기열 전체를 섞고, 끄면 켜기 전 순서로 되돌린다.
  void toggleShuffle({bool currentFirst = false}) {
    final current = state.track;
    if (current == null) {
      emit(state.copyWith(shuffle: !state.shuffle));
      return;
    }
    if (_audio != null) {
      // 섞기와 되돌리기는 엔진이 한다. 새 순서는 `queue` 이벤트로 돌아온다.
      final on = !state.shuffle;
      _command((a) => a.setShuffle(on));
      return;
    }
    if (!state.shuffle) {
      _original = state.queue;
      // 지금 곡도 섞인 목록 안의 제자리를 가진다 (재생은 끊기지 않고, 앞쪽 곡은 한 바퀴 돈 뒤에 나온다).
      final queue = currentFirst
          ? [current, ..._shuffled(state.queue.where((t) => t != current))]
          : _shuffled(state.queue);
      emit(
        state.copyWith(
          shuffle: true,
          queue: queue,
          index: queue.indexOf(current),
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

  void cycleRepeat() {
    final next = PlayerRepeatMode
        .values[(state.repeat.index + 1) % PlayerRepeatMode.values.length];
    if (_audio != null && state.track != null) {
      // 반복은 엔진이 쥔다: 화면은 바로 바꾸고 엔진에 명령만 보낸다 (엔진이 `queue` 이벤트로 확인해 준다).
      _emitFromEngine(state.copyWith(repeat: next));
      _command((a) => a.setRepeat(next));
      return;
    }
    emit(state.copyWith(repeat: next));
  }

  /// 대기열에서 [from] 곡을 [to] 자리로 옮긴다 ([to]는 옮긴 뒤의 자리).
  /// 재생 중인 곡은 그대로 이어서 재생한다.
  void moveInQueue(int from, int to) {
    final n = state.queue.length;
    if (from < 0 || from >= n || to < 0 || to >= n || from == to) return;
    final current = state.track!;
    final queue = [...state.queue];
    queue.insert(to, queue.removeAt(from));
    final moved = state.copyWith(queue: queue, index: queue.indexOf(current));
    if (_audio != null) {
      // 끌어 놓은 자리를 바로 보여 준다 (엔진 응답을 기다리면 손을 뗄 때 목록이 옛 순서로 튄다).
      // 엔진 결과가 오면 그 모습으로 맞춘다.
      _emitFromEngine(moved);
      _command((a) => a.moveInQueue((from: from, to: to)));
      return;
    }
    emit(moved);
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
