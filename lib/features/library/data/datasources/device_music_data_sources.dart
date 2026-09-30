import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/import_result.dart';
import '../../domain/entities/track.dart';

/// 플랫폼별 기기 음악 찾기. [DeviceMusicRepositoryImpl]이 플랫폼에 맞는 것을 쓴다.
abstract interface class DeviceMusicDataSource {
  Future<ScanResult> scan();
}

/// Android: MediaStore에서 음악 파일을 찾는다 (네이티브 `MediaStoreChannel`).
/// Android 13+는 READ_MEDIA_AUDIO, 12 이하는 READ_EXTERNAL_STORAGE 권한.
class MediaStoreMusicDataSource implements DeviceMusicDataSource {
  MediaStoreMusicDataSource({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _channel = MethodChannel('music_app/media_store');
  final DateTime Function() _now;

  @override
  Future<ScanResult> scan() async {
    if (!await _requestPermission()) return const ScanPermissionDenied();
    final rows =
        await _channel.invokeListMethod<Map<Object?, Object?>>('queryAudio') ??
        const [];
    final now = _now();
    return ScanFound([
      for (final r in rows)
        Track(
          id: 'device:${r['id']}',
          title: (r['title'] as String?) ?? '',
          artist: _clean(r['artist'] as String?),
          album: _clean(r['album'] as String?),
          duration: Duration(milliseconds: (r['durationMs'] as int?) ?? 0),
          uri: r['uri']! as String,
          addedAt: now,
        ),
    ]);
  }

  Future<bool> _requestPermission() async {
    // audio(13+)와 storage(12 이하) 중 기기에 맞는 쪽만 실제로 뜬다.
    final statuses = await [Permission.audio, Permission.storage].request();
    return statuses.values.any((s) => s.isGranted || s.isLimited);
  }

  /// MediaStore는 모를 때 `<unknown>`을 준다.
  static String _clean(String? v) => (v == null || v == '<unknown>') ? '' : v;
}

/// 데스크톱: 사용자가 고른 폴더 안의 음악 파일을 찾는다 (하위 폴더 포함).
/// 태그는 아직 읽지 않고 파일 이름을 제목으로 쓴다.
class DirectoryMusicDataSource implements DeviceMusicDataSource {
  DirectoryMusicDataSource({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const extensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.opus',
    '.ogg',
    '.flac',
    '.wav',
  };

  @override
  Future<ScanResult> scan() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir == null) return const ScanCancelled();
    return ScanFound(await scanDirectory(Directory(dir)));
  }

  Future<List<Track>> scanDirectory(Directory dir) async {
    final now = _now();
    final tracks = <Track>[];
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      if (dot <= 0) continue;
      if (!extensions.contains(name.substring(dot).toLowerCase())) continue;
      tracks.add(
        Track(
          id: 'file:${e.absolute.path}',
          title: name.substring(0, dot),
          artist: '',
          album: '',
          duration: Duration.zero,
          uri: e.absolute.path,
          addedAt: now,
        ),
      );
    }
    tracks.sort((a, b) => a.title.compareTo(b.title));
    return tracks;
  }
}
