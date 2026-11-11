import 'package:flutter/services.dart';

import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/video_stream.dart';
import '../engine/audio_format_policy.dart';

/// 유튜브 재생 주소를 Android 네이티브(`YoutubeResolveChannel`)가 읽는다 (D-062의 읽기를 Dart에서 옮겼다).
/// Dart는 videoId를 보내 결과만 받으므로, 앱이 백그라운드에 있어도 읽기가 끊기지 않는다.
/// 못 읽으면 null(쓸 형식 없음) 또는 [EngineException]이고, 호출한 쪽(`YoutubeResolveEngine`)이 yt-dlp로 넘어간다.
class NativeYoutubeResolver {
  NativeYoutubeResolver({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/youtube_resolve');

  final MethodChannel _channel;

  /// 소리 주소 (선호 형식 먼저, 나머지는 `fallbacks`).
  Future<AudioStream?> audio(String videoId, {String? language}) async {
    final r = await _call('audio', {
      'videoId': videoId,
      'language': language,
      'preferWebm': preferredAudioFormat() == AudioFormat.webm,
    });
    return r == null ? null : _audio(r);
  }

  /// 영상 주소 (소리가 든 형식이면 `muxed`).
  Future<VideoStream?> video(String videoId, int maxHeight) async {
    final r = await _call('video', {
      'videoId': videoId,
      'maxHeight': maxHeight,
    });
    if (r == null) return null;
    return VideoStream(
      url: r['url'] as String,
      headers: _headers(r['headers']),
      muxed: r['muxed'] as bool? ?? false,
    );
  }

  /// 오디오 언어 트랙 목록 (둘 이상일 때만 비어 있지 않다).
  Future<List<AudioLanguage>> languages(String videoId) async {
    try {
      final r = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'languages',
        {'videoId': videoId},
      );
      return [
        for (final m in r ?? const <Map<Object?, Object?>>[])
          AudioLanguage(
            id: m['id'] as String,
            name: m['name'] as String? ?? m['id'] as String,
            isDefault: m['isDefault'] as bool? ?? false,
          ),
      ];
    } on PlatformException catch (e) {
      throw EngineException(EngineFailure.failed, e.message ?? e.code);
    }
  }

  /// 유튜브와 연결을 미리 열어 둔다 (이어지는 검색 요청이 재사용한다).
  Future<void> warmUp() async {
    try {
      await _channel.invokeMethod<void>('warmUp');
    } on PlatformException {
      // 미리 열기는 실패해도 괜찮다.
    }
  }

  /// 키워드 검색 한 쪽 (유튜브 동영상만). 같은 검색어의 다음 쪽은 네이티브가 이어 읽는다.
  Future<SearchPage> search(String query, int page, int size) async {
    final r = await _call('search', {
      'query': query,
      'page': page,
      'size': size,
    });
    if (r == null) throw const EngineException(EngineFailure.failed, 'empty');
    return SearchPage(
      items: _hits(r['items']),
      hasNext: r['hasNext'] as bool? ?? false,
    );
  }

  /// 키워드로 유튜브 재생목록 찾기 한 쪽.
  Future<PlaylistSearchPage> searchPlaylists(
    String query,
    int page,
    int size,
  ) async {
    final r = await _call('searchPlaylists', {
      'query': query,
      'page': page,
      'size': size,
    });
    if (r == null) throw const EngineException(EngineFailure.failed, 'empty');
    return PlaylistSearchPage(
      items: [
        for (final m in (r['items'] as List<Object?>? ?? const []))
          _playlistHit(m! as Map<Object?, Object?>),
      ],
      hasNext: r['hasNext'] as bool? ?? false,
    );
  }

  PlaylistHit _playlistHit(Map<Object?, Object?> m) {
    final id = m['id'] as String;
    return PlaylistHit(
      id: id,
      title: m['title'] as String? ?? '',
      url: 'https://www.youtube.com/playlist?list=$id',
      channel: m['channel'] as String? ?? '',
      thumbnailUrl: m['thumbnail'] as String?,
      trackCount: (m['trackCount'] as num?)?.toInt(),
    );
  }

  /// 재생목록의 모든 곡.
  Future<PlaylistInfo> playlist(String playlistId) async {
    final r = await _call('playlist', {'playlistId': playlistId});
    if (r == null) throw const EngineException(EngineFailure.failed, 'empty');
    final entries = _hits(r['items']);
    return PlaylistInfo(
      title: r['title'] as String? ?? '',
      entries: entries,
      thumbnailUrl: entries.isEmpty ? null : entries.first.thumbnailUrl,
    );
  }

  List<MediaHit> _hits(Object? items) => [
    for (final m in (items as List<Object?>? ?? const []))
      _hit(m! as Map<Object?, Object?>),
  ];

  MediaHit _hit(Map<Object?, Object?> m) {
    final id = m['id'] as String;
    final seconds = m['seconds'] as int?;
    final channelId = m['channelId'] as String?;
    return MediaHit(
      id: id,
      title: m['title'] as String? ?? '',
      url: 'https://www.youtube.com/watch?v=$id',
      uploader: m['uploader'] as String? ?? '',
      duration: seconds == null ? null : Duration(seconds: seconds),
      thumbnailUrl: m['thumbnail'] as String?,
      channelUrl: channelId == null
          ? null
          : 'https://www.youtube.com/channel/$channelId',
      viewCount: (m['views'] as num?)?.toInt(),
      description: m['description'] as String? ?? '',
      isLive: m['isLive'] as bool? ?? false,
    );
  }

  Future<Map<Object?, Object?>?> _call(
    String method,
    Map<String, Object?> args,
  ) async {
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(method, args);
    } on PlatformException catch (e) {
      throw EngineException(EngineFailure.failed, e.message ?? e.code);
    }
  }

  AudioStream _audio(Map<Object?, Object?> m) => AudioStream(
    url: m['url'] as String,
    headers: _headers(m['headers']),
    fallbacks: [
      for (final f in (m['fallbacks'] as List<Object?>? ?? const []))
        _audio(f! as Map<Object?, Object?>),
    ],
  );

  Map<String, String> _headers(Object? h) => {
    for (final e in (h as Map<Object?, Object?>? ?? const {}).entries)
      e.key! as String: e.value! as String,
  };
}
