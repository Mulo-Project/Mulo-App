import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/home_summary.dart';
import '../../domain/usecases/home_usecases.dart';

/// 곡 하나의 재생 구간: 같은 곡을 이어 듣는 동안(일시정지 포함) 하나.
class _Session {
  _Session(this.trackId, this.id);

  final String trackId;

  /// 저장된 기록의 id (저장에 실패하면 -1).
  final Future<int> id;
  Duration listened = Duration.zero;
  Duration saved = Duration.zero;

  /// 재생 중에만 있다 (멈추면 null → 다시 재생할 때 새 기준으로 시작).
  Duration? lastPosition;
  DateTime? lastAt;
}

/// 재생 기록 저장 (상세 기능: 재생 기록 저장). 상태는 마지막으로 기록한 곡 id.
///
/// 곡이 재생되기 시작할 때 한 줄을 남기고, 재생이 이어지는 동안 **실제로 재생된 시간만**
/// 그 줄에 쌓는다. 재생 위치가 흐른 만큼만 더하되 (일시정지 · 불러오는 중에는 위치가
/// 안 움직인다), 시크로 위치가 뛴 구간은 실제 지난 시간보다 많이 더하지 않는다.
/// 쌓은 시간은 일시정지 · 곡 바뀜 · 일정 시간마다 저장한다.
class PlayRecorderCubit extends Cubit<String?> {
  PlayRecorderCubit(
    this._record,
    this._update, {
    DateTime Function()? now,
    this.flushEvery = const Duration(seconds: 15),
  }) : _now = now ?? DateTime.now,
       super(null);

  final RecordPlay _record;
  final UpdatePlayListened _update;
  final DateTime Function() _now;

  /// 재생 중에 이만큼 쌓일 때마다 저장한다 (앱이 갑자기 꺼져도 이만큼만 잃는다).
  final Duration flushEvery;

  _Session? _session;

  /// 재생 상태가 바뀔 때마다 부른다. [trackId]는 지금 곡 (없으면 null).
  void playbackChanged({
    required String? trackId,
    required Duration position,
    required bool isPlaying,
  }) {
    // 임시 저장한 음원은 파일이 아니라서 기록하지 않는다 (재생 횟수는 실제 파일의 것).
    if (trackId != null && trackId.startsWith('saved:')) trackId = null;
    final current = _session;
    if (current != null && current.trackId != trackId) {
      _pause(current);
      _session = null;
    }
    if (trackId == null) return;
    if (!isPlaying) {
      _pause(_session);
      return;
    }

    final at = _now();
    final s = _session ??= _Session(trackId, _insert(trackId, at));
    final lastPosition = s.lastPosition;
    final lastAt = s.lastAt;
    if (lastPosition != null && lastAt != null) {
      final moved = position - lastPosition;
      final elapsed = at.difference(lastAt);
      if (moved > Duration.zero && elapsed > Duration.zero) {
        s.listened += moved < elapsed ? moved : elapsed;
      }
    }
    s.lastPosition = position;
    s.lastAt = at;
    if (s.listened - s.saved >= flushEvery) _flush(s);
  }

  Future<int> _insert(String trackId, DateTime at) async {
    try {
      final id = await _record(PlayRecord(trackId: trackId, playedAt: at));
      if (!isClosed) emit(trackId);
      return id;
    } on Object {
      return -1;
    }
  }

  void _pause(_Session? s) {
    if (s == null) return;
    s.lastPosition = null;
    s.lastAt = null;
    _flush(s);
  }

  Future<void> _flush(_Session s) async {
    final total = s.listened;
    if (total == s.saved) return;
    s.saved = total;
    try {
      final id = await s.id;
      if (id >= 0) await _update(PlayListened(id, total));
    } on Object {
      // 저장 실패: 다음 저장 때 쌓인 총합으로 다시 쓴다.
    }
  }

  @override
  Future<void> close() async {
    final s = _session;
    _session = null;
    if (s != null) await _flush(s);
    return super.close();
  }
}
