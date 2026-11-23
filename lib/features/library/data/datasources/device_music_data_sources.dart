import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/import_result.dart';
import '../../domain/entities/loaded_folder.dart';
import '../../domain/entities/track.dart';

/// 플랫폼별 기기 음악 찾기. [DeviceMusicRepositoryImpl]이 플랫폼에 맞는 것을 쓴다.
abstract interface class DeviceMusicDataSource {
  /// [folders] 안(하위 폴더 포함)의 음악만 찾는다.
  Future<ScanResult> scan(List<String> folders);
}

/// Android: MediaStore에서 음악 파일을 찾아 불러오는 폴더 안의 것만 거른다 (네이티브 `MediaStoreChannel`).
/// Android 13+는 READ_MEDIA_AUDIO, 12 이하는 READ_EXTERNAL_STORAGE 권한.
class MediaStoreMusicDataSource implements DeviceMusicDataSource {
  MediaStoreMusicDataSource({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _channel = MethodChannel('music_app/media_store');
  final DateTime Function() _now;

  @override
  Future<ScanResult> scan(List<String> folders) async {
    if (!await _requestPermission()) return const ScanPermissionDenied();
    final rows =
        await _channel.invokeListMethod<Map<Object?, Object?>>('queryAudio') ??
        const [];
    // 영상은 권한이 없거나 못 읽어도 음악 불러오기는 그대로 간다.
    var videos = const <Map<Object?, Object?>>[];
    if (await _requestVideoPermission()) {
      try {
        videos =
            await _channel.invokeListMethod<Map<Object?, Object?>>(
              'queryVideo',
            ) ??
            const [];
      } on PlatformException {
        videos = const [];
      }
    }
    final now = _now();
    Track toTrack(Map<Object?, Object?> r, String prefix) => Track(
      id: '$prefix${r['id']}',
      title: (r['title'] as String?) ?? '',
      artist: _clean(r['artist'] as String?),
      album: _clean(r['album'] as String?),
      duration: Duration(milliseconds: (r['durationMs'] as int?) ?? 0),
      uri: r['uri']! as String,
      folder: normalizeFolderPath((r['folder'] as String?) ?? ''),
      // 파일이 기기에 들어온 날짜. 모르면 찾은 시각.
      addedAt: _fileDate(r['addedAtMs'], now),
    );
    // 같은 파일(mp4 등)이 음악 · 영상 양쪽에 잡히면 영상으로 한 번만 센다.
    final videoPaths = {
      for (final r in videos)
        if (r['path'] is String && (r['path']! as String).isNotEmpty)
          r['path']! as String,
    };
    return ScanFound([
      for (final r in rows)
        if (_inAny(folders, r['folder'] as String?) &&
            !videoPaths.contains(r['path']))
          toTrack(r, 'device:'),
      for (final r in videos)
        if (_inAny(folders, r['folder'] as String?))
          toTrack(r, Track.videoIdPrefix),
    ]);
  }

  static DateTime _fileDate(Object? ms, DateTime fallback) =>
      ms is int && ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : fallback;

  static bool _inAny(List<String> folders, String? folder) =>
      folder != null && folders.any((f) => isInsideFolder(folder, f));

  Future<bool> _requestPermission() async {
    // audio(13+)와 storage(12 이하) 중 기기에 맞는 쪽만 실제로 뜬다.
    final statuses = await [Permission.audio, Permission.storage].request();
    return statuses.values.any((s) => s.isGranted || s.isLimited);
  }

  Future<bool> _requestVideoPermission() async {
    // 영상 권한은 Android 13+만 따로 있다. 12 이하는 위의 storage 권한이 영상도 덮는다.
    final status = await Permission.videos.request();
    return status.isGranted || status.isLimited;
  }

  /// MediaStore는 모를 때 `<unknown>`을 준다.
  static String _clean(String? v) => (v == null || v == '<unknown>') ? '' : v;
}

/// 데스크톱: 불러오는 폴더 안의 음악 파일을 직접 찾는다 (하위 폴더 포함).
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
  Future<ScanResult> scan(List<String> folders) async {
    final tracks = <Track>[];
    final seen = <String>{};
    for (final folder in folders) {
      final dir = Directory(folder);
      if (!await dir.exists()) continue;
      for (final t in await scanDirectory(dir)) {
        if (seen.add(normalizeFolderPath(t.uri))) tracks.add(t);
      }
    }
    return ScanFound(tracks);
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
      DateTime? modified;
      try {
        modified = await e.lastModified();
      } on FileSystemException {
        modified = null;
      }
      tracks.add(
        Track(
          id: 'file:${e.absolute.path}',
          title: name.substring(0, dot),
          artist: '',
          album: '',
          duration: Duration.zero,
          uri: e.absolute.path,
          folder: normalizeFolderPath(e.parent.absolute.path),
          // 파일을 마지막으로 고친 날짜(받은 파일이면 받은 날짜). 못 읽으면 찾은 시각.
          addedAt: modified ?? now,
        ),
      );
    }
    tracks.sort((a, b) => a.title.compareTo(b.title));
    return tracks;
  }
}
