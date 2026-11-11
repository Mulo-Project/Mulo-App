import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/services.dart';

import '../../../downloads/data/datasources/cover_tag_writer.dart';
import '../../domain/entities/file_tags.dart';

/// 곡 파일([uri])의 태그를 읽는다 ([TrackTagSource]의 반대 방향). mp3(ID3) · opus · ogg(Vorbis 코멘트) · 영상 mp4(글 태그)만 읽는다.
/// Android `content://`는 형식을 `music_app/media_store`의 `mimeType`으로 확인하고, 캐시로 복사해(`music_app/lyrics`의
/// `copyToCache`) 읽은 뒤 바로 지운다. 데스크톱은 파일을 바로 읽는다.
class FileTagSource {
  FileTagSource({MethodChannel? mediaStore, MethodChannel? copy})
    : _media = mediaStore ?? const MethodChannel('music_app/media_store'),
      _copy = copy ?? const MethodChannel('music_app/lyrics');

  final MethodChannel _media;
  final MethodChannel _copy;

  static const _extensions = {'mp3', 'opus', 'ogg', 'mp4'};

  /// 임시 진단: 이번에 읽은 곡들의 결과를 종류별로 센다 ([takeSummary]로 꺼내며 비운다).
  static final _outcomes = <String, int>{};

  static void _count(String key) => _outcomes[key] = (_outcomes[key] ?? 0) + 1;

  /// "mp3 ok 3 · audio/ogg unsupported 1" 같은 한 줄. 읽은 게 없으면 빈 문자열.
  static String takeSummary() {
    final text = _outcomes.entries.map((e) => '${e.key} ${e.value}').join(' · ');
    _outcomes.clear();
    return text;
  }

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
        if (!_supportedMime(mime)) {
          _count('mime:$mime unsupported');
          return FileTags.none;
        }
        temp = await _copy.invokeMethod<String>('copyToCache', uri);
        if (temp == null) {
          _count('copy failed');
          return null;
        }
        path = temp;
      } else {
        path = uri;
        final dot = path.lastIndexOf('.');
        final ext = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
        if (!_extensions.contains(ext)) return FileTags.none;
      }
      final file = File(path);
      if (!file.existsSync()) return null;
      final tags = parse(readAllMetadata(file, getImage: false));
      _count(tags.isEmpty ? 'tag empty' : 'ok');
      return tags;
    } on MetadataParserException catch (e) {
      // 깨졌거나 태그가 없는 파일은 다시 읽어도 같다.
      _count('parse error ${e.runtimeType}');
      return FileTags.none;
    } on Object catch (e) {
      _count('read error ${e.runtimeType}');
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

  /// mp3(`audio/mpeg`)와 ogg · opus 계열(`audio/ogg` · `application/ogg` · `audio/opus` 등)이면 읽는다.
  static bool _supportedMime(String? mime) =>
      mime != null && RegExp(r'mpeg|mp3|ogg|opus|video/mp4').hasMatch(mime.toLowerCase());

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
      case Mp4Metadata():
        // 영상(mp4)의 글 태그. 커버 편집 상태(COVER_*)는 mp4에 쓰지 않아 읽지 않는다.
        return FileTags(
          title: _clean(tag.title),
          artist: _clean(tag.artist),
          album: _clean(tag.album),
          genre: _clean(tag.genre),
        );
      default:
        return FileTags.none;
    }
  }

  static String _clean(String? v) => v?.trim() ?? '';
}
