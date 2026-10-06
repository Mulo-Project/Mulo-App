import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/play_history_repository.dart';

class DriftPlayHistoryRepository implements PlayHistoryRepository {
  DriftPlayHistoryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> recordPlay(PlayRecord record) => _db
      .into(_db.plays)
      .insert(
        PlaysCompanion.insert(
          trackId: record.trackId,
          playedAt: record.playedAt,
          listenedMs: Value(record.listened.inMilliseconds),
        ),
      );

  @override
  Future<void> updateListened(int id, Duration listened) =>
      (_db.update(_db.plays)..where((p) => p.id.equals(id))).write(
        PlaysCompanion(listenedMs: Value(listened.inMilliseconds)),
      );

  @override
  Stream<List<PlayRecord>> watchPlays() =>
      (_db.select(_db.plays)..orderBy([
            (p) => OrderingTerm.desc(p.playedAt),
            (p) => OrderingTerm.desc(p.id),
          ]))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                PlayRecord(
                  trackId: r.trackId,
                  playedAt: r.playedAt,
                  listened: Duration(milliseconds: r.listenedMs),
                ),
            ],
          );
}
