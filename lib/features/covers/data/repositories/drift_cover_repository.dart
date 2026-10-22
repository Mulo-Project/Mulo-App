import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/cover_art.dart';
import '../../domain/repositories/cover_repository.dart';

/// 기기 사진은 앱 지원 폴더(`covers/`)로 복사하고 경로를, 웹 이미지는 주소만 DB에 저장한다.
/// 원본 사진이 지워지거나 옮겨져도 커버는 남는다.
class DriftCoverRepository implements CoverRepository {
  DriftCoverRepository(this._db, {Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final AppDatabase _db;
  final Future<Directory> Function() _baseDir;

  @override
  Future<Map<String, CoverArt>> loadAll() async {
    final rows = await _db.select(_db.covers).get();
    final covers = <String, CoverArt>{};
    for (final r in rows) {
      final art = _toArt(r);
      if (art != null) covers[r.key] = art;
    }
    return covers;
  }

  /// 파일이 사라진 기기 사진은 건너뛴다.
  static CoverArt? _toArt(CoverRow r) {
    final t = CoverTransform(
      scale: r.scale,
      dx: r.dx,
      dy: r.dy,
      rotation: r.rotation,
    );
    final url = r.url;
    if (url != null) return CoverArt.web(url, transform: t);
    return File(r.path).existsSync()
        ? CoverArt.file(r.path, transform: t)
        : null;
  }

  @override
  Future<CoverArt> save(
    String key,
    String sourcePath, {
    CoverTransform transform = CoverTransform.identity,
  }) async {
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
    await _upsert(key, path: stored.path, url: null, transform: transform);
    if (old != null) await _deleteQuietly(old);
    return CoverArt.file(stored.path, transform: transform);
  }

  @override
  Future<CoverArt> saveUrl(
    String key,
    String url, {
    CoverTransform transform = CoverTransform.identity,
  }) async {
    final old = await _pathOf(key);
    await _upsert(key, path: '', url: url, transform: transform);
    if (old != null) await _deleteQuietly(old);
    return CoverArt.web(url, transform: transform);
  }

  @override
  Future<void> saveTransform(String key, CoverTransform transform) =>
      (_db.update(_db.covers)..where((c) => c.key.equals(key))).write(
        CoversCompanion(
          scale: Value(transform.scale),
          dx: Value(transform.dx),
          dy: Value(transform.dy),
          rotation: Value(transform.rotation),
        ),
      );

  @override
  Future<void> remove(String key) async {
    final old = await _pathOf(key);
    await (_db.delete(_db.covers)..where((c) => c.key.equals(key))).go();
    if (old != null) await _deleteQuietly(old);
  }

  Future<void> _upsert(
    String key, {
    required String path,
    required String? url,
    required CoverTransform transform,
  }) => _db
      .into(_db.covers)
      .insertOnConflictUpdate(
        CoversCompanion.insert(
          key: key,
          path: path,
          url: Value(url),
          scale: Value(transform.scale),
          dx: Value(transform.dx),
          dy: Value(transform.dy),
          rotation: Value(transform.rotation),
        ),
      );

  /// 앱 폴더에 복사해 둔 파일 경로 (웹 이미지면 null).
  Future<String?> _pathOf(String key) async {
    final row = await (_db.select(
      _db.covers,
    )..where((c) => c.key.equals(key))).getSingleOrNull();
    final path = row?.path;
    return path == null || path.isEmpty ? null : path;
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // 이미 없으면 그만.
    }
  }
}
