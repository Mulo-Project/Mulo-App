import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/feed_video.dart';
import '../../domain/repositories/channel_feed.dart';

/// GET 요청 하나: 상태 코드와 본문 (테스트에서 바꿔 끼운다).
typedef FeedGet = Future<({int status, String body})> Function(Uri uri);

Future<({int status, String body})> _defaultGet(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(uri);
    req.headers.set(
      HttpHeaders.userAgentHeader,
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Mobile Safari/537.36',
    );
    req.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.8');
    final res = await req.close().timeout(const Duration(seconds: 20));
    final body = await res.transform(utf8.decoder).join();
    return (status: res.statusCode, body: body);
  } finally {
    client.close(force: true);
  }
}

final _channelIdPattern = RegExp(r'UC[0-9A-Za-z_-]{22}');

/// 유튜브 채널 RSS(`feeds/videos.xml?channel_id=`)로 최근 영상을 읽는다. 키 · 로그인이 필요 없다.
class YoutubeFeedClient implements ChannelFeed {
  YoutubeFeedClient({FeedGet? get}) : _get = get ?? _defaultGet;

  final FeedGet _get;

  @override
  Future<String?> resolveChannelId(String channelUrl) async {
    final uri = Uri.tryParse(channelUrl.trim());
    if (uri == null || !(uri.host.endsWith('youtube.com'))) return null;
    final segments = uri.pathSegments;
    final at = segments.indexOf('channel');
    if (at >= 0 && at + 1 < segments.length) {
      final id = segments[at + 1];
      if (_channelIdPattern.hasMatch(id) && id.length == 24) return id;
    }
    // 핸들(@이름) · 사용자 이름 주소는 채널 페이지에서 채널 id를 읽는다.
    final page = await _get(uri);
    if (page.status != 200) return null;
    return parseChannelIdFromPage(page.body);
  }

  @override
  Future<List<FeedVideo>> fetch(String channelId) async {
    final res = await _get(
      Uri.https('www.youtube.com', '/feeds/videos.xml', {
        'channel_id': channelId,
      }),
    );
    if (res.status != 200) {
      throw HttpException('feed ${res.status}');
    }
    return parseFeed(res.body);
  }
}

/// 채널 페이지 HTML에서 채널 id를 찾는다. 못 찾으면 null.
String? parseChannelIdFromPage(String html) {
  for (final pattern in [
    RegExp(r'"externalId":"(UC[0-9A-Za-z_-]{22})"'),
    RegExp(r'"channelId":"(UC[0-9A-Za-z_-]{22})"'),
    RegExp(r'youtube\.com/channel/(UC[0-9A-Za-z_-]{22})'),
    RegExp(r'channel_id=(UC[0-9A-Za-z_-]{22})'),
  ]) {
    final m = pattern.firstMatch(html);
    if (m != null) return m.group(1);
  }
  return null;
}

/// 채널 RSS(Atom)를 영상 목록으로. 읽을 수 없는 항목은 건너뛴다.
List<FeedVideo> parseFeed(String xml) {
  final videos = <FeedVideo>[];
  for (final m in RegExp(r'<entry>([\s\S]*?)</entry>').allMatches(xml)) {
    final entry = m.group(1)!;
    final id = _tag(entry, 'yt:videoId');
    final title = _tag(entry, 'title');
    final published = DateTime.tryParse(_tag(entry, 'published') ?? '');
    if (id == null || title == null || published == null) continue;
    videos.add(
      FeedVideo(
        id: id,
        title: title,
        publishedAt: published.toUtc(),
        author:
            _tag(
              RegExp(r'<author>([\s\S]*?)</author>').stringMatch(entry) ?? '',
              'name',
            ) ??
            '',
        thumbnailUrl: RegExp(r'<media:thumbnail[^>]*\burl="([^"]+)"')
            .firstMatch(entry)
            ?.group(1),
        viewCount: int.tryParse(
          RegExp(r'<media:statistics[^>]*\bviews="(\d+)"')
                  .firstMatch(entry)
                  ?.group(1) ??
              '',
        ),
      ),
    );
  }
  return videos;
}

String? _tag(String text, String name) {
  final m = RegExp('<$name>([\\s\\S]*?)</$name>').firstMatch(text);
  return m == null ? null : _unescape(m.group(1)!.trim());
}

String _unescape(String s) => s
    .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      return String.fromCharCode(int.parse(m.group(1)!));
    })
    .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      return String.fromCharCode(int.parse(m.group(1)!, radix: 16));
    })
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');
