import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/entities/subtitle_track.dart';
import '../../domain/repositories/downloader_engine.dart';

/// 주소의 페이지 본문을 읽는다 (테스트에서 바꿔 끼운다). 못 읽으면 null.
typedef PageReader = Future<String?> Function(Uri url);

/// SoundCloud 아티스트 페이지의 `og:image`(프로필 이미지) 주소를 읽는다. 없으면 null.
/// 곡 썸네일은 곡 커버라서 아티스트 이미지가 아니므로, 페이지 머리말의 이 값을 쓴다.
String? soundcloudAvatarFromHtml(String html) {
  for (final m in RegExp(
    r'<meta\b[^>]*>',
    caseSensitive: false,
  ).allMatches(html)) {
    final tag = m.group(0)!;
    if (!RegExp(
      r'''(property|name)\s*=\s*["']og:image["']''',
      caseSensitive: false,
    ).hasMatch(tag)) {
      continue;
    }
    final content = RegExp(
      r'''content\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(tag)?.group(1);
    if (content == null || !content.startsWith('http')) continue;
    // 작은 `-large`(100px) 대신 큰 이미지로.
    return content
        .replaceAll('&amp;', '&')
        .replaceFirst(RegExp(r'-(large|t200x200|t300x300)\.'), '-t500x500.');
  }
  return null;
}

bool _isSoundcloud(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host == 'soundcloud.com' || host.endsWith('.soundcloud.com');
}

/// SoundCloud 아티스트 이미지를 채워 주는 엔진 덮개. yt-dlp의 채널 정보에는 프로필 이미지가
/// 없거나 이름이 달라 비는 일이 있어서, 안쪽 엔진이 못 채운 이미지를 아티스트 페이지에서 읽는다.
/// 다른 사이트 · 다른 기능은 그대로 안쪽 엔진에 넘긴다.
class SoundcloudAvatarEngine implements DownloaderEngine {
  SoundcloudAvatarEngine(this._inner, {PageReader? readPage})
    : _readPage = readPage ?? _fetchPage;

  final DownloaderEngine _inner;
  final PageReader _readPage;

  @override
  Future<ChannelInfo> fetchChannel(String url) async {
    if (!_isSoundcloud(url)) return _inner.fetchChannel(url);
    ChannelInfo? info;
    try {
      info = await _inner.fetchChannel(url);
    } on EngineException {
      // 안쪽 엔진이 못 읽어도(서버 모드 등) 아래에서 이미지는 읽어 본다.
    }
    if (info?.thumbnailUrl != null) return info!;
    final html = await _readPage(Uri.parse(url));
    final avatar = html == null ? null : soundcloudAvatarFromHtml(html);
    if (avatar == null) {
      if (info != null) return info;
      throw const EngineException(EngineFailure.notFound);
    }
    return ChannelInfo(
      thumbnailUrl: avatar,
      subscriberCount: info?.subscriberCount,
    );
  }

  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) => _inner.search(
    query,
    source: source,
    page: page,
    size: size,
    newest: newest,
  );

  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  }) => _inner.searchPlaylists(query, page: page, size: size);

  @override
  Future<MediaInfo> fetchInfo(String url) => _inner.fetchInfo(url);

  @override
  Future<AudioStream> resolveAudioStream(String url, {bool refresh = false}) =>
      _inner.resolveAudioStream(url, refresh: refresh);
  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) => _inner.fetchSubtitles(url, preferLanguages: preferLanguages);
}

Future<String?> _fetchPage(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await client.getUrl(url);
    req.headers.set(
      'user-agent',
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    );
    final resp = await req.close().timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    // 머리말(meta)은 앞쪽에 있으니 앞 200KB만 읽는다.
    final bytes = <int>[];
    await for (final chunk in resp) {
      bytes.addAll(chunk);
      if (bytes.length > 200 * 1024) break;
    }
    return utf8.decode(bytes, allowMalformed: true);
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}
