import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/entities/subtitle_track.dart';
import '../../domain/entities/video_stream.dart';
import '../../domain/repositories/downloader_engine.dart';
import 'json_fields.dart';

/// GET 요청 하나: 상태 코드와 본문을 돌려준다 (테스트에서 바꿔 끼운다).
typedef HttpGet = Future<({int status, String body})> Function(
  Uri uri,
  Map<String, String> headers,
);

Future<({int status, String body})> _defaultGet(
  Uri uri,
  Map<String, String> headers,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(uri);
    headers.forEach(req.headers.set);
    final res = await req.close().timeout(const Duration(seconds: 60));
    final body = await res.transform(utf8.decoder).join();
    return (status: res.statusCode, body: body);
  } finally {
    client.close(force: true);
  }
}

/// 서버 모드: Mulo 서버 REST(`/api/v1/search`, `/api/v1/info`)로 찾는다.
class ServerEngine implements DownloaderEngine {
  ServerEngine({required String baseUrl, this.tokenProvider, HttpGet? get})
    : _base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      _get = get ?? _defaultGet;

  final String _base;
  final HttpGet _get;

  /// 로그인 토큰 (JWT). 로그인 기능이 붙기 전에는 null.
  final Future<String?> Function()? tokenProvider;

  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) async {
    final json = await _getJson('/search', {
      'q': query,
      'page': '$page',
      'size': '$size',
      if (source.serverQuery != null) 'source': source.serverQuery!,
      if (newest) 'sort': 'date',
    });
    final items = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_hit)
        .toList();
    return SearchPage(items: items, hasNext: json['hasNext'] == true);
  }

  /// 서버 `GET /api/v1/search?type=playlist` — 서버 명세에 아직 없다.
  /// 서버가 몰라서 실패하면 바깥 덮개가 다른 방법으로 찾는다.
  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    final json = await _getJson('/search', {
      'q': query,
      'type': 'playlist',
      'page': '$page',
      'size': '$size',
    });
    final items = <PlaylistHit>[];
    for (final j in (json['items'] as List? ?? const [])) {
      if (j is! Map<String, dynamic>) continue;
      final id = parseText(j['playlistId'] ?? j['id']);
      if (id == null) continue;
      items.add(
        PlaylistHit(
          id: id,
          title: j['title'] as String? ?? '',
          url:
              parseText(j['url']) ??
              'https://www.youtube.com/playlist?list=$id',
          channel: parseText(j['uploader'] ?? j['channel']) ?? '',
          thumbnailUrl: parseText(j['thumbnail']),
          trackCount: parseCount(j['trackCount'] ?? j['videoCount']),
        ),
      );
    }
    return PlaylistSearchPage(items: items, hasNext: json['hasNext'] == true);
  }

  @override
  Future<MediaInfo> fetchFullInfo(String url) => fetchInfo(url);

  @override
  Future<MediaInfo> fetchInfo(String url) async {
    final json = await _getJson('/info', {'url': url});
    if (json['type'] == 'playlist') {
      return PlaylistInfo(
        title: json['title'] as String? ?? '',
        entries: (json['entries'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_hit)
            .toList(),
        thumbnailUrl: parseText(json['thumbnail']),
      );
    }
    return VideoInfo(_hit(json));
  }

  /// 서버 명세에 채널 조회가 없어서 쓰지 않는다. 상세 보기는 곡 정보에 실려 온
  /// `subscriberCount` · `channelThumbnail`만 보여 준다.
  @override
  Future<ChannelInfo> fetchChannel(String url) async =>
      throw const EngineException(EngineFailure.unavailable);

  /// 서버 명세에 스트림 주소 조회가 없어서 쓰지 않는다. 미리 듣기는 이 기기에서
  /// yt-dlp를 실행할 수 있을 때(로컬 엔진)만 된다.
  @override
  Future<AudioStream> resolveAudioStream(
    String url, {
    bool refresh = false,
    String? audioLanguage,
  }) async => throw const EngineException(EngineFailure.unavailable);

  @override
  Future<VideoStream> resolveVideoStream(String url, {int maxHeight = 360}) async =>
      throw const EngineException(EngineFailure.unavailable);

  @override
  Future<void> warmUp() async {}

  /// 서버 명세에 오디오 트랙 조회가 없어서 고를 수 있는 언어가 없다.
  @override
  Future<List<AudioLanguage>> fetchAudioLanguages(String url) async => const [];

  /// 서버 `GET /api/v1/subtitles?url=&lang=ko,en` — 서버 명세에 아직 없는 제안 형식이다:
  /// `{"lang": "ko", "auto": false, "cues": [{"startMs": 1200, "text": "..."}]}`.
  /// 자막이 없거나(404) 서버가 아직 몰라도 null을 돌려준다.
  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) async {
    final Map<String, dynamic> json;
    try {
      json = await _getJson('/subtitles', {
        'url': url,
        'lang': preferLanguages.join(','),
      });
    } on EngineException catch (e) {
      if (e.failure == EngineFailure.notFound) return null;
      rethrow;
    }
    final cues = <SubtitleCue>[
      for (final c in (json['cues'] as List? ?? const []))
        if (c is Map<String, dynamic> &&
            c['startMs'] is num &&
            parseText(c['text']) != null)
          SubtitleCue(
            Duration(milliseconds: (c['startMs'] as num).round()),
            parseText(c['text'])!,
          ),
    ];
    if (cues.isEmpty) return null;
    return SubtitleTrack(
      language: parseText(json['lang']) ?? '',
      automatic: json['auto'] == true,
      cues: cues,
    );
  }

  MediaHit _hit(Map<String, dynamic> j) {
    final id = j['videoId'] as String? ?? '';
    final seconds = j['durationSec'];
    return MediaHit(
      id: id,
      title: j['title'] as String? ?? '',
      // 서버가 주소를 주면 그대로, 없으면 유튜브 곡 주소.
      url: j['url'] as String? ?? 'https://www.youtube.com/watch?v=$id',
      uploader: j['uploader'] as String? ?? '',
      duration: seconds is num ? Duration(seconds: seconds.round()) : null,
      thumbnailUrl: j['thumbnail'] as String?,
      categories: parseCategories(j['categories']),
      downloaded: j['downloaded'] == true,
      channelUrl: parseText(j['channelUrl']),
      viewCount: parseCount(j['viewCount']),
      uploadedAt: parseDate(j['uploadDate']),
      description: parseText(j['description']) ?? '',
      likeCount: parseCount(j['likeCount']),
      subscriberCount: parseCount(j['subscriberCount']),
      channelThumbnailUrl: parseText(j['channelThumbnail']),
      creators: parseStrings(j['creators']),
      subtitleLangs: parseStrings(j['subtitleLangs']),
      autoSubtitleLangs: parseStrings(j['autoSubtitleLangs']),
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> query,
  ) async {
    final token = await tokenProvider?.call();
    final uri = Uri.parse('$_base/api/v1$path').replace(queryParameters: query);
    final ({int status, String body}) res;
    try {
      res = await _get(uri, {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
    } on SocketException catch (e) {
      throw EngineException(EngineFailure.network, e.message);
    } on TimeoutException {
      throw const EngineException(EngineFailure.timeout, 'timeout');
    } on HttpException catch (e) {
      throw EngineException(EngineFailure.network, e.message);
    }
    if (res.status == 401 || res.status == 403) {
      throw const EngineException(EngineFailure.unauthorized);
    }
    if (res.status == 404) {
      throw EngineException(EngineFailure.notFound, _errorMessage(res.body));
    }
    if (res.status < 200 || res.status >= 300) {
      throw EngineException(EngineFailure.failed, _errorMessage(res.body));
    }
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw const EngineException(EngineFailure.failed, 'bad response');
    } on TypeError {
      throw const EngineException(EngineFailure.failed, 'bad response');
    }
  }

  /// 서버 에러 형식 `{"code": "...", "message": "..."}`의 message.
  String _errorMessage(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['message'] is String) return j['message'] as String;
    } on FormatException {
      // 본문이 JSON이 아니면 빈 문자열.
    }
    return '';
  }
}
