import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:ui' as ui;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 임시 진단: 커버를 읽은 결과를 종류별로 센다.
final _notes = <String, int>{};

void _note(String key) => _notes[key] = (_notes[key] ?? 0) + 1;

/// 음악 파일에서 내장 커버 이미지의 원본 바이트를 꺼낸다. 없으면 null.
abstract interface class EmbeddedPictureReader {
  Future<Uint8List?> read(String uri);
}

/// Android: `content://` 곡은 네이티브 `MediaMetadataRetriever` (`music_app/media_store`).
/// 이 방법이 못 읽는 ogg · opus · webm 계열은 캐시로 복사해 태그를 직접 읽는다
/// (`music_app/lyrics`의 `copyToCache`, 읽은 뒤 바로 지움). 다른 형식은 복사하지 않는다.
class MediaStorePictureReader implements EmbeddedPictureReader {
  MediaStorePictureReader({MethodChannel? channel, MethodChannel? copyChannel})
    : _channel = channel ?? const MethodChannel('music_app/media_store'),
      _copy = copyChannel ?? const MethodChannel('music_app/lyrics');

  final MethodChannel _channel;
  final MethodChannel _copy;

  static final _tagOnly = RegExp(r'ogg|opus|webm|weba', caseSensitive: false);

  @override
  Future<Uint8List?> read(String uri) async {
    final bytes = await _channel.invokeMethod<Uint8List>('embeddedPicture', {
      'uri': uri,
    });
    if (bytes != null && bytes.isNotEmpty) {
      _note('retriever ok');
      return bytes;
    }
    final mime = await _channel.invokeMethod<String>('mimeType', {'uri': uri});
    if (mime == null || !_tagOnly.hasMatch(mime)) {
      _note('no cover (mime:$mime)');
      return null;
    }
    final temp = await _copy.invokeMethod<String>('copyToCache', uri);
    if (temp == null) {
      _note('copy failed (mime:$mime)');
      return null;
    }
    try {
      final read = await FilePictureReader().read(temp);
      _note(read == null ? 'tag has no picture (mime:$mime)' : 'tag picture ok (mime:$mime)');
      return read;
    } finally {
      try {
        File(temp).deleteSync();
      } on FileSystemException {
        // 이미 없으면 그만.
      }
    }
  }
}

/// 데스크톱: 파일 태그를 직접 읽는다 (audio_metadata_reader: mp3 · flac · m4a · ogg 등).
class FilePictureReader implements EmbeddedPictureReader {
  @override
  Future<Uint8List?> read(String uri) async {
    final file = File(uri);
    if (!file.existsSync()) return null;
    final pictures = readMetadata(file, getImage: true).pictures;
    if (pictures.isNotEmpty) return pictures.first.bytes;
    // opus · ogg: 라이브러리가 그림 칸으로 안 주면, 코멘트의 METADATA_BLOCK_PICTURE를 직접 푼다.
    try {
      final raw = readAllMetadata(file, getImage: true);
      if (raw is VorbisMetadata) {
        if (raw.pictures.isNotEmpty) return raw.pictures.first.bytes;
        return pictureFromVorbisComments(raw.unknowns);
      }
    } on Object {
      // 못 읽으면 커버 없음.
    }
    return null;
  }
}

/// Vorbis 코멘트의 `METADATA_BLOCK_PICTURE`(base64로 감싼 FLAC 그림 블록)에서 그림 바이트를 꺼낸다. 없거나 깨졌으면 null.
Uint8List? pictureFromVorbisComments(Map<String, String> comments) {
  for (final e in comments.entries) {
    if (e.key.toUpperCase() != 'METADATA_BLOCK_PICTURE') continue;
    try {
      final bytes = base64.decode(e.value.trim());
      final data = ByteData.sublistView(bytes);
      var at = 4; // 그림 종류
      final mimeLen = data.getUint32(at);
      at += 4 + mimeLen;
      final descLen = data.getUint32(at);
      at += 4 + descLen;
      at += 16; // 가로 · 세로 · 색 깊이 · 색 수
      final size = data.getUint32(at);
      at += 4;
      if (size == 0 || at + size > bytes.length) return null;
      return Uint8List.sublistView(bytes, at, at + size);
    } on Object {
      return null;
    }
  }
  return null;
}

/// 내장 커버를 긴 변 [maxSide]px 이하로 줄인 PNG 임시 파일(앱 캐시 폴더)로 만든다.
/// 형식을 못 읽거나 이미지가 없으면 null.
class EmbeddedCoverSource {
  EmbeddedCoverSource(this._reader, {this.maxSide = 512});

  final EmbeddedPictureReader _reader;
  final int maxSide;

  static const _folder = 'embedded_cover_tmp';

  /// 임시 진단: "retriever ok 3 · tag has no picture (mime:audio/ogg) 2" 같은 한 줄 (꺼내면 비운다).
  static String takeSummary() {
    final text = _notes.entries.map((e) => '${e.key} ${e.value}').join(' · ');
    _notes.clear();
    return text;
  }

  Future<String?> extract(String uri) async {
    try {
      final raw = await _reader.read(uri);
      debugPrint('MuloTag cover read: ${raw?.length}');
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
    } on Object catch (e) {
      debugPrint('MuloTag cover read failed: $e');
      _note('error ${e.runtimeType}');
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
