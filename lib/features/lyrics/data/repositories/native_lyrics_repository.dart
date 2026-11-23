import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/database/native_db.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../datasources/file_picker_lyrics_source.dart';

/// 가사를 앱 지원 폴더(`lyrics/`)에 파일로 두고 경로를 네이티브 DB에 저장한다.
class NativeLyricsRepository implements LyricsRepository {
  NativeLyricsRepository(
    this._db,
    this._embedded, {
    Future<Directory> Function()? baseDir,
  }) : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final NativeDb _db;
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

    // 싱크 ↔ 일반 글로 바뀌어 경로가 달라지면 네이티브가 옛 파일을 지운다.
    await _db.call<void>('saveLyricsPath', {
      'trackId': trackId,
      'path': file.path,
    });
    return lyrics;
  }

  @override
  Future<void> remove(String trackId) =>
      _db.call<void>('removeLyrics', {'trackId': trackId});

  Future<String?> _pathOf(String trackId) =>
      _db.call<String>('lyricsPath', {'trackId': trackId});

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
}
