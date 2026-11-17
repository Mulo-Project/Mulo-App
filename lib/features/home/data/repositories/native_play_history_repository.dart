import '../../../../core/database/native_db.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/play_history_repository.dart';

class NativePlayHistoryRepository implements PlayHistoryRepository {
  NativePlayHistoryRepository(this._db);

  final NativeDb _db;

  @override
  Future<int> recordPlay(PlayRecord record) async =>
      (await _db.call<int>('recordPlay', {
        'trackId': record.trackId,
        'playedAtSec': record.playedAt.millisecondsSinceEpoch ~/ 1000,
        'listenedMs': record.listened.inMilliseconds,
      }))!;

  @override
  Future<void> updateListened(int id, Duration listened) =>
      _db.call<void>('updateListened', {
        'id': id,
        'listenedMs': listened.inMilliseconds,
      });

  @override
  Stream<List<PlayRecord>> watchPlays() => _db.watch({'plays'}, () async {
    final rows = await _db.list('plays');
    return [
      for (final r in rows)
        PlayRecord(
          trackId: r['trackId']! as String,
          playedAt: dateOfSec(r['playedAtSec']),
          listened: Duration(milliseconds: (r['listenedMs']! as num).toInt()),
        ),
    ];
  });
}
