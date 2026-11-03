import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../../../core/cache/cached_web_image.dart';
import '../../../../core/cover/cover_paint.dart';
import '../../../covers/domain/entities/cover_art.dart';
import 'ffmpeg_tag_writer.dart';

/// 받은 음원 파일의 태그에 커버 이미지를 넣는다 (다른 음악 앱에서도 커버가 보이도록).
///
/// 앱 안의 커버와 같게 고른 확대 · 위치대로 정사각형으로 잘라 [side]px PNG로 넣는다.
/// 태그를 쓸 수 없는 형식(받은 그대로의 webm 등)이거나 이미지를 못 구하면 파일을 건드리지 않고 false.
class CoverTagWriter {
  const CoverTagWriter({this.side = 512, this.ffmpeg});

  final int side;

  /// opus · ogg · mp3 태그를 쓰는 ffmpeg 쓰기. 없으면 그 형식은 건드리지 않는다.
  final FfmpegTagWriter? ffmpeg;

  /// 태그에 커버를 쓸 수 있는 확장자. ffmpeg가 만든 mp3는 ID3 태그가 이미 있다.
  /// (opus · ogg는 [ffmpeg]가 쓴다. webm은 쓰지 않는다. mp3도 ffmpeg가 되면 ffmpeg로 쓴다.)
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
    int? color,
  }) async {
    final ext = extension.toLowerCase();
    final viaFfmpeg =
        ffmpeg != null && FfmpegTagWriter.extensions.contains(ext);
    if (!extensions.contains(ext) && !viaFfmpeg) return false;
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
      if (viaFfmpeg) {
        final done = await ffmpeg!.write(
          audio,
          extension: ext,
          title: title,
          artist: artist,
          album: album,
          genre: genre,
          lyrics: lyrics,
          coverPng: png,
          coverSide: side,
          extra: coverExtra(cover, thumbnailUrl, color),
        );
        // mp3는 ffmpeg가 안 되는 기기(lite 등)에서 라이브러리로 쓴다. opus · ogg는 쓸 방법이 이것뿐이다.
        if (done && ext == 'mp3' && text(lyrics) != null) {
          _ensureStandardLyrics(audio, lyrics!);
        }
        if (done || !extensions.contains(ext)) return done;
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
    } on Object catch (e) {
      FfmpegTagWriter.lastError = '${FfmpegTagWriter.lastError ?? ''} lib: $e'.trim();
      // 못 써도 받은 곡은 그대로 저장한다 (앱 안 커버는 DB에 따로 있다).
      return false;
    }
  }

  /// ffmpeg가 쓴 mp3 가사는 표준 가사 칸(USLT)이 아니라 사용자 정의 칸(TXXX)에 들어갈 수 있다.
  /// 앱과 다른 플레이어가 읽는 표준 칸에 가사가 없으면 라이브러리로 한 번 더 써 준다.
  /// 복사본에 써서 가사 · 제목 · 커버 수가 그대로일 때만 원본을 바꾼다 (아니면 원본은 그대로).
  static void _ensureStandardLyrics(File audio, String lyrics) {
    final copy = File('${audio.path}.uslt');
    try {
      final want = lyrics.trim();
      final before = readMetadata(audio, getImage: true);
      if (before.lyrics?.trim() == want) return;
      audio.copySync(copy.path);
      updateMetadata(copy, (m) => m.setLyrics(lyrics));
      final after = readMetadata(copy, getImage: true);
      final same =
          after.lyrics?.trim() == want &&
          after.title == before.title &&
          after.artist == before.artist &&
          after.pictures.length == before.pictures.length;
      if (same) copy.renameSync(audio.path);
    } on Object {
      // 못 해도 ffmpeg가 쓴 원본은 그대로 둔다.
    } finally {
      try {
        if (copy.existsSync()) copy.deleteSync();
      } on FileSystemException {
        // 임시 파일이라 못 지워도 그만.
      }
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
      final recorder = ui.PictureRecorder();
      paintCover(ui.Canvas(recorder), side.toDouble(), image, t);
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

/// [coverExtra]로 쓴 사용자 정의 태그를 되읽는다 (키는 대소문자 구분 없이). 없거나 깨진 칸은 null · 기본값.
({String? source, CoverTransform transform, int? color}) parseCoverExtra(
  Map<String, String> tags,
) {
  String? get(String key) {
    for (final e in tags.entries) {
      if (e.key.toUpperCase() == key && e.value.trim().isNotEmpty) {
        return e.value.trim();
      }
    }
    return null;
  }

  var transform = CoverTransform.identity;
  final parts = get('COVER_TRANSFORM')?.split(',').map(double.tryParse);
  if (parts != null && parts.length >= 3 && !parts.contains(null)) {
    final v = parts.cast<double>().toList();
    transform = CoverTransform(
      scale: v[0],
      dx: v[1],
      dy: v[2],
      rotation: v.length > 3 ? v[3] : 0,
    ).clamped();
  }
  final hex = get('COVER_COLOR');
  return (
    source: get('COVER_SOURCE'),
    transform: transform,
    color: hex == null ? null : int.tryParse(hex, radix: 16),
  );
}

/// 커버 편집 상태를 파일에 남기는 사용자 정의 태그: 원본 웹 주소 · 확대 · 위치 · 색.
/// 앱이 파일만 읽어도 커버를 다시 잘라 보여 줄 수 있다. 값이 없으면 그 칸은 쓰지 않는다.
Map<String, String> coverExtra(
  CoverArt? cover,
  String? thumbnailUrl,
  int? color,
) {
  final url = cover?.url ?? (cover == null ? thumbnailUrl : null);
  final t = cover?.transform ?? CoverTransform.identity;
  return {
    if (url != null && url.isNotEmpty) 'COVER_SOURCE': url,
    if (!t.isIdentity)
      'COVER_TRANSFORM': '${t.scale},${t.dx},${t.dy},${t.rotation}',
    if (color != null) 'COVER_COLOR': color.toRadixString(16).padLeft(8, '0'),
  };
}
