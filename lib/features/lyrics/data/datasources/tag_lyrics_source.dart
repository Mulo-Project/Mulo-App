import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/services.dart';

import '../../domain/repositories/lyrics_repository.dart';

/// 음원 파일 태그에서 가사를 읽는다 (audio_metadata_reader: mp3 · flac · m4a · ogg 등).
/// Android의 `content://` 곡은 네이티브(`music_app/lyrics`)가 캐시 폴더로 복사해 준 파일을 읽고 바로 지운다.
class TagLyricsSource implements EmbeddedLyricsSource {
  TagLyricsSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/lyrics');

  final MethodChannel _channel;

  @override
  Future<String?> read(String trackUri) async {
    if (trackUri.isEmpty) return null;
    String? temp;
    try {
      final String path;
      if (trackUri.startsWith('content://')) {
        temp = await _channel.invokeMethod<String>('copyToCache', trackUri);
        if (temp == null) return null;
        path = temp;
      } else if (trackUri.startsWith('file://')) {
        path = Uri.parse(trackUri).toFilePath();
      } else if (trackUri.contains('://')) {
        return null;
      } else {
        path = trackUri;
      }
      final file = File(path);
      if (!file.existsSync()) return null;
      final text = readMetadata(file).lyrics?.trim();
      return text == null || text.isEmpty ? null : text;
    } on Exception {
      // 지원하지 않는 형식 · 깨진 태그 · 복사 실패 모두 "가사 없음"으로 본다.
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
}
