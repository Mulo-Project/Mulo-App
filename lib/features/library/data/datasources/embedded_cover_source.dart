import 'dart:io';
import 'dart:ui' as ui;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 음악 파일에서 내장 커버 이미지의 원본 바이트를 꺼낸다. 없으면 null.
abstract interface class EmbeddedPictureReader {
  Future<Uint8List?> read(String uri);
}

/// Android: `content://` 곡은 네이티브 `MediaMetadataRetriever` (`music_app/media_store`).
class MediaStorePictureReader implements EmbeddedPictureReader {
  MediaStorePictureReader({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/media_store');

  final MethodChannel _channel;

  @override
  Future<Uint8List?> read(String uri) =>
      _channel.invokeMethod<Uint8List>('embeddedPicture', {'uri': uri});
}

/// 데스크톱: 파일 태그를 직접 읽는다 (audio_metadata_reader: mp3 · flac · m4a · ogg 등).
class FilePictureReader implements EmbeddedPictureReader {
  @override
  Future<Uint8List?> read(String uri) async {
    final file = File(uri);
    if (!file.existsSync()) return null;
    final pictures = readMetadata(file, getImage: true).pictures;
    return pictures.isEmpty ? null : pictures.first.bytes;
  }
}

/// 내장 커버를 긴 변 [maxSide]px 이하로 줄인 PNG 임시 파일(앱 캐시 폴더)로 만든다.
/// 형식을 못 읽거나 이미지가 없으면 null.
class EmbeddedCoverSource {
  EmbeddedCoverSource(this._reader, {this.maxSide = 512});

  final EmbeddedPictureReader _reader;
  final int maxSide;

  static const _folder = 'embedded_cover_tmp';

  Future<String?> extract(String uri) async {
    try {
      final raw = await _reader.read(uri);
      if (raw == null || raw.isEmpty) return null;
      final png = await _shrink(raw);
      if (png == null) return null;
      final dir = Directory(
        '${(await getApplicationCacheDirectory()).path}/$_folder',
      );
      await dir.create(recursive: true);
      final file = File(
        '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(png, flush: true);
      return file.path;
    } on Object {
      // 지원하지 않는 형식 · 깨진 태그 · 읽기 실패는 모두 "내장 커버 없음".
      return null;
    }
  }

  Future<void> discard(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // 이미 없으면 그만.
    }
  }

  /// 긴 변이 [maxSide]보다 크면 비율을 지켜 줄이고, 항상 PNG로 다시 인코딩한다.
  Future<Uint8List?> _shrink(Uint8List raw) async {
    final probe = await ui.instantiateImageCodec(raw);
    final first = await probe.getNextFrame();
    final w = first.image.width;
    final h = first.image.height;
    first.image.dispose();
    probe.dispose();
    final shrink = (w >= h ? w : h) > maxSide;
    final codec = await ui.instantiateImageCodec(
      raw,
      targetWidth: shrink && w >= h ? maxSide : null,
      targetHeight: shrink && h > w ? maxSide : null,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    return data?.buffer.asUint8List();
  }
}
