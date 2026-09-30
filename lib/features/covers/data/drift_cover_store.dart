import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../presentation/cover_controller.dart';

/// 커버 이미지를 앱 지원 폴더(`covers/`)로 복사하고 경로를 DB에 저장한다.
/// 원본 사진이 지워지거나 옮겨져도 커버는 남는다.
class DriftCoverStore implements CoverStore {
  DriftCoverStore(this._db, {Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final AppDatabase _db;
  final Future<Directory> Function() _baseDir;

  @override
  Future<Map<String, String>> loadAll() async {
    final rows = await _db.select(_db.covers).get();
    return {
      for (final r in rows)
        if (File(r.path).existsSync()) r.key: r.path,
    };
  }

  @override
  Future<String> save(String key, String sourcePath) async {
    final dir = Directory('${(await _baseDir()).path}/covers');
    await dir.create(recursive: true);
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot > 0 ? sourcePath.substring(dot) : '.img';
    // 같은 이름을 덮어쓰면 이미지 캐시가 옛 그림을 보여 주므로 매번 새 이름.
    final name =
        '${key.replaceAll(RegExp(r'[^\w]'), '_')}_'
        '${DateTime.now().microsecondsSinceEpoch}$ext';
    final stored = await File(sourcePath).copy('${dir.path}/$name');

    final old = await _pathOf(key);
    await _db
        .into(_db.covers)
        .insertOnConflictUpdate(
          CoversCompanion.insert(key: key, path: stored.path),
        );
    if (old != null) await _deleteQuietly(old);
    return stored.path;
  }

  @override
  Future<void> remove(String key) async {
    final old = await _pathOf(key);
    await (_db.delete(_db.covers)..where((c) => c.key.equals(key))).go();
    if (old != null) await _deleteQuietly(old);
  }

  Future<String?> _pathOf(String key) async => (await (_db.select(
    _db.covers,
  )..where((c) => c.key.equals(key))).getSingleOrNull())?.path;

  static Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // 이미 없으면 그만.
    }
  }
}
