import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 앱 캐시 폴더가 끝없이 커지지 않게 시작할 때 한 번 정리한다.
/// - `cover_cache`(웹 커버 사본): 합계가 [maxCoverBytes]를 넘으면 오래 안 쓴 것부터 지운다 (지워도 다시 받아 채운다).
/// - `embedded_cover_tmp`(내장 커버 임시 파일): 쓰고 바로 지우는 파일이라 남은 것은 모두 찌꺼기다.
/// 실패해도 앱에는 영향이 없다.
class CacheCleaner {
  const CacheCleaner._();

  static const maxCoverBytes = 64 * 1024 * 1024;

  static Future<void> run() async {
    try {
      final base = (await getApplicationCacheDirectory()).path;
      final sep = Platform.pathSeparator;
      await _deleteDir(Directory('$base${sep}embedded_cover_tmp'));
      await _trim(Directory('$base${sep}cover_cache'), maxCoverBytes);
    } on Object {
      // 정리는 최선만 한다.
    }
  }

  static Future<void> _deleteDir(Directory dir) async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static Future<void> _trim(Directory dir, int maxBytes) async {
    if (!await dir.exists()) return;
    final files = <(File, FileStat)>[];
    var total = 0;
    await for (final e in dir.list()) {
      if (e is! File) continue;
      final stat = await e.stat();
      files.add((e, stat));
      total += stat.size;
    }
    if (total <= maxBytes) return;
    files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    for (final (file, stat) in files) {
      if (total <= maxBytes) break;
      try {
        await file.delete();
        total -= stat.size;
      } on FileSystemException {
        // 쓰는 중이면 건너뛴다.
      }
    }
  }
}
