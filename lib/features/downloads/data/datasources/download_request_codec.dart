import '../../domain/entities/download_request.dart';

/// 받기 요청을 JSON으로 (네이티브 받기 큐에 넘길 값).
Map<String, dynamic> encodeDownloadRequest(DownloadRequest r) => {
  'title': r.title,
  'artist': r.artist,
  if (r.album.isNotEmpty) 'album': r.album,
  'genre': r.genre,
  'playlistIds': r.playlistIds.toList(),
  'format': r.format?.name,
  'savePath': r.savePath,
  'durationMs': r.duration?.inMilliseconds,
  'color': r.color,
  'thumbnailUrl': r.thumbnailUrl,
  'url': r.url,
  if (r.importLyrics) 'importLyrics': true,
  'lyricsLanguage': ?r.lyricsLanguage,
  if (!r.lyricsSkipSounds) 'lyricsSkipSounds': false,
  'lyricsText': ?r.lyricsText,
  'audioLanguage': ?r.audioLanguage,
  if (r.videoFormat case final v?) ...{
    'videoFormat': v.name,
    'videoHeight': r.videoHeight,
  },
  if (r.cover case final art?)
    'cover': {
      'path': art.path,
      'url': art.url,
      'scale': art.transform.scale,
      'dx': art.transform.dx,
      'dy': art.transform.dy,
      if (art.transform.rotation != 0) 'rotation': art.transform.rotation,
    },
};
