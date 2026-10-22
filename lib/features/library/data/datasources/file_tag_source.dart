import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/services.dart';

import '../../../downloads/data/datasources/cover_tag_writer.dart';
import '../../domain/entities/file_tags.dart';

/// 곡 파일([uri])의 태그를 읽는다 ([TrackTagSource]의 반대 방향). mp3(ID3)와 opus · ogg(Vorbis 코멘트)만 읽는다.
/// Android `content://`는 형식을 `music_app/media_store`의 `mimeType`으로 확인하고, 캐시로 복사해(`music_app/lyrics`의
/// `copyToCache`) 읽은 뒤 바로 지운다. 데스크톱은 파일을 바로 읽는다.
class FileTagSource {
  FileTagSource({MethodChannel? mediaStore, MethodChannel? copy})
    : _media = mediaStore ?? const MethodChannel('music_app/media_store'),
      _copy = copy ?? const MethodChannel('music_app/lyrics');

  final MethodChannel _media;
  final MethodChannel _copy;

  static const _extensions = {'mp3', 'opus', 'ogg'};

  /// 지원하지 않는 형식 · 태그 없음은 [FileTags.none], 파일을 못 읽으면 null.
  Future<FileTags?> read(String uri) async {
    if (uri.isEmpty) return null;
    String? temp;
    try {
      final String path;
      if (uri.startsWith('content://')) {
        final mime = await _media.invokeMethod<String>('mimeType', {
          'uri': uri,
        });
        if (!_supportedMime(mime)) return FileTags.none;
        temp = await _copy.invokeMethod<String>('copyToCache', uri);
        if (temp == null) return null;
        path = temp;
      } else {
        path = uri;
        final dot = path.lastIndexOf('.');
        final ext = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
        if (!_extensions.contains(ext)) return FileTags.none;
      }
      final file = File(path);
      if (!file.existsSync()) return null;
      return parse(readAllMetadata(file, getImage: false));
    } on MetadataParserException {
      // 깨졌거나 태그가 없는 파일은 다시 읽어도 같다.
      return FileTags.none;
    } on Object {
      return null;
    } finally {
      if (temp != null) {
        try {
          File(temp).deleteSync();
        } on FileSystemException {
          // 이미 없으면 그만.
        }
      }
    }
  }

  static bool _supportedMime(String? mime) =>
      mime == 'audio/mpeg' ||
      mime == 'audio/mp3' ||
      mime == 'audio/ogg' ||
      mime == 'audio/opus';

  /// 읽은 태그를 앱 값으로. 앱이 쓴 사용자 정의 칸(`COVER_*`)은 ID3의 TXXX · Vorbis 코멘트에서 읽는다.
  static FileTags parse(Object tag) {
    switch (tag) {
      case Mp3Metadata():
        final extra = parseCoverExtra(tag.customMetadata);
        return FileTags(
          title: _clean(tag.songName),
          artist: _clean(tag.leadPerformer ?? tag.bandOrOrchestra),
          album: _clean(tag.album),
          genre: _clean(tag.genres.isEmpty ? null : tag.genres.first),
          coverSource: extra.source,
          coverTransform: extra.transform,
          coverColor: extra.color,
        );
      case VorbisMetadata():
        final extra = parseCoverExtra(tag.unknowns);
        return FileTags(
          title: _clean(tag.title.firstOrNull),
          artist: _clean(tag.artist.firstOrNull),
          album: _clean(tag.album.firstOrNull),
          genre: _clean(tag.genres.firstOrNull),
          coverSource: extra.source,
          coverTransform: extra.transform,
          coverColor: extra.color,
        );
      default:
        return FileTags.none;
    }
  }

  static String _clean(String? v) => v?.trim() ?? '';
}
