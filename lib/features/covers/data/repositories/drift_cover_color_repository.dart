import '../../../../core/database/app_database.dart';
import '../../domain/repositories/cover_repository.dart';

/// 고른 커버 색(ARGB)을 DB에 저장한다.
class DriftCoverColorRepository implements CoverColorRepository {
  DriftCoverColorRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Map<String, int>> loadAll() async {
    final rows = await _db.select(_db.coverColors).get();
    return {for (final r in rows) r.key: r.color};
  }

  @override
  Future<void> save(String key, int color) => _db
      .into(_db.coverColors)
      .insertOnConflictUpdate(
        CoverColorsCompanion.insert(key: key, color: color),
      );

  @override
  Future<void> remove(String key) =>
      (_db.delete(_db.coverColors)..where((c) => c.key.equals(key))).go();
}
