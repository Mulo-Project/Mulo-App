import '../../../../core/database/native_db.dart';
import '../../domain/repositories/cover_repository.dart';

/// 고른 커버 색(ARGB)을 네이티브 DB에 저장한다.
class NativeCoverColorRepository implements CoverColorRepository {
  NativeCoverColorRepository(this._db);

  final NativeDb _db;

  @override
  Future<Map<String, int>> loadAll() async {
    final rows = await _db.call<Map<Object?, Object?>>('coverColors');
    return {
      for (final e in (rows ?? const {}).entries)
        e.key! as String: (e.value! as num).toInt(),
    };
  }

  @override
  Future<void> save(String key, int color) =>
      _db.call<void>('saveCoverColor', {'key': key, 'color': color});

  @override
  Future<void> remove(String key) =>
      _db.call<void>('removeCoverColor', {'key': key});
}
