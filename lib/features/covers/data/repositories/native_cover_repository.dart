import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/database/native_db.dart';
import '../../domain/entities/cover_art.dart';
import '../../domain/repositories/cover_repository.dart';

/// 기기 사진은 앱 지원 폴더(`covers/`)로 복사하고 경로를, 웹 이미지는 주소만 DB에 저장한다.
/// 원본 사진이 지워지거나 옮겨져도 커버는 남는다. DB 쓰기(와 바뀐 커버의 옛 파일 정리)는 네이티브가 한다.
class NativeCoverRepository implements CoverRepository {
  NativeCoverRepository(this._db, {Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final NativeDb _db;
  final Future<Directory> Function() _baseDir;

  @override
  Future<Map<String, CoverArt>> loadAll() async {
    final covers = <String, CoverArt>{};
    for (final r in await _db.list('covers')) {
      final t = _transformOf(r);
      final url = r['url'] as String?;
      covers[r['key']! as String] = url != null
          ? CoverArt.web(url, transform: t)
          : CoverArt.file(r['path']! as String, transform: t);
    }
    return covers;
  }

  static CoverTransform _transformOf(Map<String, Object?> r) => CoverTransform(
    scale: (r['scale']! as num).toDouble(),
    dx: (r['dx']! as num).toDouble(),
    dy: (r['dy']! as num).toDouble(),
    rotation: (r['rotation']! as num).toDouble(),
  );

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
    await _save(key, path: stored.path, url: null, transform: transform);
    return CoverArt.file(stored.path, transform: transform);
  }

  @override
  Future<CoverArt> saveUrl(
    String key,
    String url, {
    CoverTransform transform = CoverTransform.identity,
  }) async {
    await _save(key, path: '', url: url, transform: transform);
    return CoverArt.web(url, transform: transform);
  }

  @override
  Future<void> saveTransform(String key, CoverTransform transform) =>
      _db.call<void>('saveCoverTransform', {'key': key, ..._fields(transform)});

  @override
  Future<void> remove(String key) =>
      _db.call<void>('removeCover', {'key': key});

  Future<void> _save(
    String key, {
    required String path,
    required String? url,
    required CoverTransform transform,
  }) => _db.call<void>('saveCover', {
    'key': key,
    'path': path,
    'url': url,
    ..._fields(transform),
  });

  static Map<String, Object?> _fields(CoverTransform t) => {
    'scale': t.scale,
    'dx': t.dx,
    'dy': t.dy,
    'rotation': t.rotation,
  };
}
