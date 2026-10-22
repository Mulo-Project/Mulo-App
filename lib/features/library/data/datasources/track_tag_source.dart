import 'dart:io';

import 'package:flutter/services.dart';

import '../../../covers/domain/entities/cover_art.dart';
import '../../../downloads/data/datasources/cover_tag_writer.dart';
import '../../../downloads/data/datasources/ffmpeg_tag_writer.dart';
import '../../domain/repositories/track_tag_repository.dart';

/// 곡 파일([uri])의 태그를 쓴다. Android `content://`는 캐시로 복사 → 태그 쓰기 → 같은 주소에 덮어쓰기
/// (`music_app/lyrics`의 `copyToCache`, `music_app/media_store`의 `overwriteAudio`). 데스크톱은 파일을 바로 쓴다.
///
/// 결과로 "쓸 수 없는 곡"과 "쓰려다 실패"를 가른다. 실패를 알려야 하는 곡은 ffmpeg로 mp3 · opus 태그를 쓰는
/// 곡(full 빌드)뿐이고, 그 밖의 곡(ffmpeg 없음 · 다른 형식 · 파일 접근 불가)은 [TagWriteResult.unsupported].
class TrackTagSource {
  TrackTagSource({
    this._writer = const CoverTagWriter(ffmpeg: FfmpegTagWriter()),
    this._ffmpeg = const FfmpegTagWriter(),
    MethodChannel? mediaStore,
    MethodChannel? copy,
  }) : _media = mediaStore ?? const MethodChannel('music_app/media_store'),
       _copy = copy ?? const MethodChannel('music_app/lyrics');

  final CoverTagWriter _writer;
  final FfmpegTagWriter _ffmpeg;
  final MethodChannel _media;
  final MethodChannel _copy;
  bool? _ffmpegAvailable;

  Future<TagWriteResult> write(
    String uri, {
    required String title,
    required String artist,
    required String album,
    required String genre,
    CoverArt? cover,
    int? color,
  }) async {
    if (uri.isEmpty) return TagWriteResult.unsupported;
    var viaFfmpeg = false;
    try {
      final isContent = uri.startsWith('content://');
      final String extension;
      if (isContent) {
        final ext = _extensionOfMime(
          await _media.invokeMethod<String>('mimeType', {'uri': uri}),
        );
        if (ext == null) return TagWriteResult.unsupported;
        extension = ext;
      } else {
        if (!File(uri).existsSync()) return TagWriteResult.unsupported;
        extension = _extensionOfPath(uri);
      }
      viaFfmpeg =
          FfmpegTagWriter.extensions.contains(extension.toLowerCase()) &&
          (_ffmpegAvailable ??= await _ffmpeg.available());
      // 못 쓰면: ffmpeg로 쓰는 곡은 실패, 그 밖은 쓰지 않는 곡(DB만).
      final fail = viaFfmpeg
          ? TagWriteResult.failed
          : TagWriteResult.unsupported;

      final denied = viaFfmpeg
          ? TagWriteResult.denied
          : TagWriteResult.unsupported;

      Future<bool> embed(File file) => _writer.embed(
        file,
        extension: extension,
        cover: cover,
        color: color,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
      );

      if (!isContent) {
        return await embed(File(uri)) ? TagWriteResult.written : fail;
      }
      final temp = await _copy.invokeMethod<String>('copyToCache', uri);
      if (temp == null) return denied;
      try {
        if (!await embed(File(temp))) return fail;
        final ok =
            await _media.invokeMethod<bool>('overwriteAudio', {
              'uri': uri,
              'path': temp,
            }) ??
            false;
        return ok ? TagWriteResult.written : denied;
      } finally {
        try {
          File(temp).deleteSync();
        } on FileSystemException {
          // 이미 없으면 그만.
        }
      }
    } on Object {
      return viaFfmpeg ? TagWriteResult.failed : TagWriteResult.unsupported;
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
