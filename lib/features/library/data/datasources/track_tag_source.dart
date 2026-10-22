import 'dart:io';

import 'package:flutter/services.dart';

import '../../../covers/domain/entities/cover_art.dart';
import '../../../downloads/data/datasources/cover_tag_writer.dart';
import '../../../downloads/data/datasources/ffmpeg_tag_writer.dart';

/// 곡 파일([uri])의 태그를 쓴다. Android `content://`는 캐시로 복사 → 태그 쓰기 → 같은 주소에 덮어쓰기
/// (`music_app/lyrics`의 `copyToCache`, `music_app/media_store`의 `overwriteAudio`). 데스크톱은 파일을 바로 쓴다.
class TrackTagSource {
  TrackTagSource({
    this._writer = const CoverTagWriter(ffmpeg: FfmpegTagWriter()),
    MethodChannel? mediaStore,
    MethodChannel? copy,
  }) : _media = mediaStore ?? const MethodChannel('music_app/media_store'),
       _copy = copy ?? const MethodChannel('music_app/lyrics');

  final CoverTagWriter _writer;
  final MethodChannel _media;
  final MethodChannel _copy;

  Future<bool> write(
    String uri, {
    required String title,
    required String artist,
    required String album,
    required String genre,
    CoverArt? cover,
    int? color,
  }) async {
    if (uri.isEmpty) return false;
    try {
      if (!uri.startsWith('content://')) {
        final file = File(uri);
        if (!file.existsSync()) return false;
        return await _writer.embed(
          file,
          extension: _extensionOfPath(uri),
          cover: cover,
          color: color,
          title: title,
          artist: artist,
          album: album,
          genre: genre,
        );
      }
      final extension = _extensionOfMime(
        await _media.invokeMethod<String>('mimeType', {'uri': uri}),
      );
      if (extension == null) return false;
      final temp = await _copy.invokeMethod<String>('copyToCache', uri);
      if (temp == null) return false;
      try {
        final wrote = await _writer.embed(
          File(temp),
          extension: extension,
          cover: cover,
          color: color,
          title: title,
          artist: artist,
          album: album,
          genre: genre,
        );
        if (!wrote) return false;
        return await _media.invokeMethod<bool>('overwriteAudio', {
              'uri': uri,
              'path': temp,
            }) ??
            false;
      } finally {
        try {
          File(temp).deleteSync();
        } on FileSystemException {
          // 이미 없으면 그만.
        }
      }
    } on Object {
      return false;
    }
  }

  static String _extensionOfPath(String path) {
    final dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot + 1);
  }

  static String? _extensionOfMime(String? mime) => switch (mime) {
    'audio/mpeg' || 'audio/mp3' => 'mp3',
    'audio/mp4' || 'audio/x-m4a' || 'audio/m4a' || 'audio/aac' => 'm4a',
    'audio/ogg' || 'audio/opus' => 'opus',
    _ => null,
  };
}
