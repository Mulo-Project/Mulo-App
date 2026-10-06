import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// 웹 이미지를 처음 보여 줄 때 작은 사본을 앱 캐시 폴더에 저장해 두고, 다음부터(오프라인
/// 포함) 그 사본을 쓰는 [ImageProvider]. 주소는 그대로 기억하고, 사본은 보여 주기 위한
/// 캐시일 뿐이라 시스템이 지워도 다시 받아 채운다. 저장하지 못하는 환경에서는 그냥 받아서 보여 준다.
class CachedWebImage extends ImageProvider<CachedWebImage> {
  const CachedWebImage(this.url);

  final String url;

  static const _folder = 'cover_cache';
  static const _timeout = Duration(seconds: 15);

  @override
  Future<CachedWebImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CachedWebImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: url,
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await _bytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  Future<Uint8List> _bytes() async {
    final file = await _cacheFile();
    if (file != null && await file.exists()) {
      final saved = await file.readAsBytes();
      if (saved.isNotEmpty) return saved;
    }
    final bytes = await _download();
    if (file != null) {
      try {
        await file.writeAsBytes(bytes, flush: true);
      } on Object {
        // 사본을 못 남겨도 이번엔 그대로 보여 준다.
      }
    }
    return bytes;
  }

  Future<File?> _cacheFile() async {
    try {
      final base = await getApplicationCacheDirectory();
      final dir = Directory('${base.path}${Platform.pathSeparator}$_folder');
      await dir.create(recursive: true);
      final name = sha1.convert(url.codeUnits).toString();
      return File('${dir.path}${Platform.pathSeparator}$name');
    } on Object {
      return null;
    }
  }

  Future<Uint8List> _download() async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: Uri.parse(url),
        );
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(_timeout)) {
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.isEmpty) throw StateError('빈 이미지: $url');
      return bytes;
    } finally {
      client.close(force: true);
    }
  }

  @override
  bool operator ==(Object other) => other is CachedWebImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
