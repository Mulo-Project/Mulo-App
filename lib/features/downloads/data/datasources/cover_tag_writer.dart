import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../../../core/cache/cached_web_image.dart';
import '../../../covers/domain/entities/cover_art.dart';

/// 받은 음원 파일의 태그에 커버 이미지를 넣는다 (다른 음악 앱에서도 커버가 보이도록).
///
/// 앱 안의 커버와 같게 고른 확대 · 위치대로 정사각형으로 잘라 [side]px PNG로 넣는다.
/// 태그를 쓸 수 없는 형식(받은 그대로의 webm 등)이거나 이미지를 못 구하면 파일을 건드리지 않고 false.
class CoverTagWriter {
  const CoverTagWriter({this.side = 512});

  final int side;

  /// 태그에 커버를 쓸 수 있는 확장자. ffmpeg가 만든 mp3는 ID3 태그가 이미 있다.
  /// (opus · ogg · webm은 태그 쓰기를 지원하지 않아 넣지 않는다.)
  static const extensions = {'mp3', 'm4a'};

  Future<bool> embed(
    File audio, {
    required String extension,
    CoverArt? cover,
    String? thumbnailUrl,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? lyrics,
  }) async {
    if (!extensions.contains(extension.toLowerCase())) return false;
    try {
      // 커버를 못 구해도 글 정보(제목 · 아티스트 등)는 파일에 남긴다.
      Uint8List? png;
      final source = await _sourceFile(cover, thumbnailUrl);
      if (source != null) {
        png = await _squarePng(
          await source.readAsBytes(),
          cover?.transform ?? CoverTransform.identity,
        );
      }
      String? text(String? v) => v == null || v.trim().isEmpty ? null : v;
      if (png == null &&
          text(title) == null &&
          text(artist) == null &&
          text(album) == null &&
          text(genre) == null &&
          text(lyrics) == null) {
        return false;
      }
      updateMetadata(audio, (m) {
        if (text(title) != null) m.setTitle(title);
        if (text(artist) != null) m.setArtist(artist);
        if (text(album) != null) m.setAlbum(album);
        if (text(genre) != null) m.setGenres([genre!]);
        if (text(lyrics) != null) m.setLyrics(lyrics);
        if (png != null) {
          m.setPictures([Picture(png, 'image/png', PictureType.coverFront)]);
        }
      });
      return true;
    } on Object {
      // 못 써도 받은 곡은 그대로 저장한다 (앱 안 커버는 DB에 따로 있다).
      return false;
    }
  }

  static Future<File?> _sourceFile(
    CoverArt? cover,
    String? thumbnailUrl,
  ) async {
    final path = cover?.path;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      return file.existsSync() ? file : null;
    }
    final url = cover?.url ?? thumbnailUrl;
    if (url == null || url.isEmpty) return null;
    return CachedWebImage.localCopy(url);
  }

  Future<Uint8List?> _squarePng(Uint8List bytes, CoverTransform t) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    try {
      final r = t.visibleRect(image.width.toDouble(), image.height.toDouble());
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        image,
        ui.Rect.fromLTWH(r.left, r.top, r.side, r.side),
        ui.Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      final picture = recorder.endRecording();
      final out = await picture.toImage(side, side);
      picture.dispose();
      final data = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}
