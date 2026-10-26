import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../datasources/file_picker_lyrics_source.dart';

/// 가사를 앱 지원 폴더(`lyrics/`)에 파일로 두고 경로를 DB에 저장한다.
class DriftLyricsRepository implements LyricsRepository {
  DriftLyricsRepository(
    this._db,
    this._embedded, {
    Future<Directory> Function()? baseDir,
  }) : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final AppDatabase _db;
  final EmbeddedLyricsSource _embedded;
  final Future<Directory> Function() _baseDir;

  @override
  Future<Lyrics?> load(String trackId, String trackUri) async {
    final saved = await _pathOf(trackId);
    if (saved != null) {
      final text = await _readQuietly(saved);
      if (text != null) return Lyrics.parse(text);
    }
    final sibling = _siblingLrc(trackUri);
    if (sibling != null) {
      final text = await _readQuietly(sibling);
      final lyrics = text == null ? null : Lyrics.parse(text);
      if (lyrics != null) return lyrics;
    }
    final tag = await _embedded.read(trackUri);
    return tag == null ? null : Lyrics.parse(tag);
  }

  @override
  Future<Set<String>> savedTrackIds() async =>
      (await _db.select(_db.lyricsFiles).get())
          .map((row) => row.trackId)
          .toSet();

  @override
  Future<Lyrics?> loadSaved(String trackId) async {
    final path = await _pathOf(trackId);
    if (path == null) return null;
    final text = await _readQuietly(path);
    return text == null ? null : Lyrics.parse(text);
  }

  @override
  Future<Lyrics?> save(String trackId, String text) async {
    final lyrics = Lyrics.parse(text);
    if (lyrics == null) {
      await remove(trackId);
      return null;
    }
    final dir = Directory('${(await _baseDir()).path}/lyrics');
    await dir.create(recursive: true);
    final safeId = trackId.replaceAll(RegExp(r'[^\w]'), '_');
    final ext = lyrics.isSynced ? 'lrc' : 'txt';
    final file = File('${dir.path}/$safeId.$ext');
    await file.writeAsString(lyrics.raw);

    final old = await _pathOf(trackId);
    await _db
        .into(_db.lyricsFiles)
        .insertOnConflictUpdate(
          LyricsFilesCompanion.insert(trackId: trackId, path: file.path),
        );
    // 싱크 ↔ 일반 글로 바뀌면 확장자가 달라 옛 파일이 남는다.
    if (old != null && old != file.path) await _deleteQuietly(old);
    return lyrics;
  }

  @override
  Future<void> remove(String trackId) async {
    final old = await _pathOf(trackId);
    await (_db.delete(
      _db.lyricsFiles,
    )..where((l) => l.trackId.equals(trackId))).go();
    if (old != null) await _deleteQuietly(old);
  }

  Future<String?> _pathOf(String trackId) async => (await (_db.select(
    _db.lyricsFiles,
  )..where((l) => l.trackId.equals(trackId))).getSingleOrNull())?.path;

  /// 음원 파일 옆의 같은 이름 `.lrc` 경로. 파일 경로가 아니면(content:// 등) null.
  static String? _siblingLrc(String uri) {
    if (uri.isEmpty) return null;
    final String path;
    if (uri.startsWith('file://')) {
      path = Uri.parse(uri).toFilePath();
    } else if (uri.contains('://')) {
      return null;
    } else {
      path = uri;
    }
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    if (dot <= slash + 1) return null;
    return '${path.substring(0, dot)}.lrc';
  }

  static Future<String?> _readQuietly(String path) async {
    try {
      return decodeLyricsBytes(await File(path).readAsBytes());
    } on FileSystemException {
      return null;
    }
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // 이미 없으면 그만.
    }
  }
}
