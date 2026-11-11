import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/entities/track_file_info.dart';

/// 음악 파일 지우기. 플랫폼별로 [PlatformTrackFileDataSource]가 알아서 고른다.
abstract interface class TrackFileDataSource {
  /// [uri]의 파일을 지운다. 이미 없으면 true, 못 지우면 false.
  Future<bool> delete(String uri);

  /// [uri]의 파일 크기 · 형식 · 비트레이트 · 샘플레이트. 읽을 수 없으면 null.
  Future<TrackFileInfo?> info(String uri);
}

/// Android의 `content://`는 MediaStore로(네이티브 `MediaStoreChannel`),
/// 그 밖의 경로는 파일로 직접 지운다.
/// Android 10+에서 앱이 만든 파일이 아니면 시스템이 삭제 동의 창을 띄우고,
/// 사용자가 거절하면 false가 돌아온다.
class PlatformTrackFileDataSource implements TrackFileDataSource {
  static const _channel = MethodChannel('music_app/media_store');

  @override
  Future<bool> delete(String uri) async {
    if (uri.isEmpty) return true;
    if (uri.startsWith('content://')) {
      try {
        return await _channel.invokeMethod<bool>('deleteAudio', {'uri': uri}) ??
            false;
      } on PlatformException {
        return false;
      }
    }
    try {
      final file = File(uri);
      if (await file.exists()) await file.delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  @override
  Future<TrackFileInfo?> info(String uri) async {
    if (uri.isEmpty) return null;
    if (uri.startsWith('content://')) {
      try {
        final map = await _channel.invokeMapMethod<String, Object?>(
          'fileInfo',
          {'uri': uri},
        );
        if (map == null || map.isEmpty) return null;
        return TrackFileInfo(
          sizeBytes: (map['size'] as num?)?.toInt(),
          mime: map['mime'] as String?,
          bitrate: (map['bitrate'] as num?)?.toInt(),
          sampleRate: (map['sampleRate'] as num?)?.toInt(),
          width: (map['width'] as num?)?.toInt(),
          height: (map['height'] as num?)?.toInt(),
        );
      } on PlatformException {
        return null;
      }
    }
    try {
      final file = File(uri);
      if (!await file.exists()) return null;
      return TrackFileInfo(sizeBytes: await file.length());
    } on FileSystemException {
      return null;
    }
  }
}
