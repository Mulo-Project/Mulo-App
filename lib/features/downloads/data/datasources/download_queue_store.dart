import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../covers/domain/entities/cover_art.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/entities/download_request.dart';

/// 앱을 껐다 켜도 이어 받기 위해 저장해 두는 대기열 항목 하나.
class StoredDownload {
  const StoredDownload({
    required this.id,
    required this.request,
    required this.status,
    this.progress = 0,
    this.error = '',
    this.partMime,
  });

  final String id;
  final DownloadRequest request;
  final DownloadStatus status;
  final double progress;
  final String error;

  /// 받다 만 임시 파일의 형식. 이어받을 때 같은 형식의 주소인지 확인한다.
  final String? partMime;
}

/// 대기열과 "받은 곡 ↔ 원본 주소" 기록의 저장소.
abstract interface class DownloadQueueStore {
  Future<List<StoredDownload>> loadQueue();

  Future<void> saveQueue(List<StoredDownload> items);

  /// 원본 주소 키(`downloadSourceKey`) → 받아서 만든 곡 id.
  Future<Map<String, String>> loadSources();

  Future<void> saveSources(Map<String, String> sources);
}

/// shared_preferences에 JSON으로 저장한다 (대기열은 작다).
class PrefsDownloadQueueStore implements DownloadQueueStore {
  static const _queueKey = 'download.queue';
  static const _sourcesKey = 'download.sources';

  @override
  Future<List<StoredDownload>> loadQueue() async {
    final raw = (await SharedPreferences.getInstance()).getString(_queueKey);
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List<dynamic>)
          _decodeItem(e as Map<String, dynamic>),
      ];
    } on Object {
      // 깨진 기록은 버리고 빈 대기열로 시작한다.
      return const [];
    }
  }

  @override
  Future<void> saveQueue(List<StoredDownload> items) async =>
      (await SharedPreferences.getInstance()).setString(
        _queueKey,
        jsonEncode([for (final e in items) _encodeItem(e)]),
      );

  @override
  Future<Map<String, String>> loadSources() async {
    final raw = (await SharedPreferences.getInstance()).getString(_sourcesKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as String),
      );
    } on Object {
      return {};
    }
  }

  @override
  Future<void> saveSources(Map<String, String> sources) async =>
      (await SharedPreferences.getInstance()).setString(
        _sourcesKey,
        jsonEncode(sources),
      );

  static Map<String, dynamic> _encodeItem(StoredDownload e) => {
    'id': e.id,
    'status': e.status.name,
    'progress': e.progress,
    'error': e.error,
    'partMime': e.partMime,
    'request': encodeDownloadRequest(e.request),
  };

  static StoredDownload _decodeItem(Map<String, dynamic> m) => StoredDownload(
    id: m['id'] as String,
    status: DownloadStatus.values.byName(m['status'] as String),
    progress: (m['progress'] as num?)?.toDouble() ?? 0,
    error: m['error'] as String? ?? '',
    partMime: m['partMime'] as String?,
    request: decodeDownloadRequest(m['request'] as Map<String, dynamic>),
  );
}

/// 받기 요청을 JSON으로 (대기열 저장용).
Map<String, dynamic> encodeDownloadRequest(DownloadRequest r) => {
  'title': r.title,
  'artist': r.artist,
  'genre': r.genre,
  'playlistIds': r.playlistIds.toList(),
  'quality': r.quality?.name,
  'format': r.format?.name,
  'savePath': r.savePath,
  'durationMs': r.duration?.inMilliseconds,
  'color': r.color,
  'thumbnailUrl': r.thumbnailUrl,
  'url': r.url,
  if (r.importLyrics) 'importLyrics': true,
  'lyricsLanguage': ?r.lyricsLanguage,
  if (!r.lyricsSkipSounds) 'lyricsSkipSounds': false,
  if (r.cover case final art?)
    'cover': {
      'path': art.path,
      'url': art.url,
      'scale': art.transform.scale,
      'dx': art.transform.dx,
      'dy': art.transform.dy,
    },
};

DownloadRequest decodeDownloadRequest(Map<String, dynamic> m) {
  final cover = m['cover'] as Map<String, dynamic>?;
  CoverArt? art;
  if (cover != null) {
    final t = CoverTransform(
      scale: (cover['scale'] as num?)?.toDouble() ?? 1,
      dx: (cover['dx'] as num?)?.toDouble() ?? 0,
      dy: (cover['dy'] as num?)?.toDouble() ?? 0,
    );
    final url = cover['url'] as String?;
    final path = cover['path'] as String?;
    if (url != null) {
      art = CoverArt.web(url, transform: t);
    } else if (path != null) {
      art = CoverArt.file(path, transform: t);
    }
  }
  final quality = m['quality'] as String?;
  final format = m['format'] as String?;
  final durationMs = m['durationMs'] as int?;
  return DownloadRequest(
    title: m['title'] as String? ?? '',
    artist: m['artist'] as String? ?? '',
    genre: m['genre'] as String? ?? '',
    playlistIds: {...?(m['playlistIds'] as List<dynamic>?)?.cast<String>()},
    quality: quality == null ? null : Quality.values.byName(quality),
    format: format == null ? null : AudioFormat.values.byName(format),
    savePath: m['savePath'] as String? ?? '',
    duration: durationMs == null ? null : Duration(milliseconds: durationMs),
    color: m['color'] as int?,
    thumbnailUrl: m['thumbnailUrl'] as String?,
    cover: art,
    url: m['url'] as String? ?? '',
    importLyrics: m['importLyrics'] == true,
    lyricsLanguage: m['lyricsLanguage'] as String?,
    lyricsSkipSounds: m['lyricsSkipSounds'] != false,
  );
}
