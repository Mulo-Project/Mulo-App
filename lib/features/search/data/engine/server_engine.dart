import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
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
      if (source == SearchSource.web) 'source': 'web',
      if (newest) 'sort': 'date',
    });
    final items = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_hit)
        .toList();
    return SearchPage(items: items, hasNext: json['hasNext'] == true);
  }

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
  Future<AudioStream> resolveAudioStream(String url) async =>
      throw const EngineException(EngineFailure.unavailable);

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
      throw const EngineException(EngineFailure.network, 'timeout');
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
