import 'dart:convert';
import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../domain/entities/channel_details.dart';
import '../../domain/entities/channel_hit.dart';
import '../../domain/repositories/channel_searcher.dart';

/// `youtube_explode_dart`의 채널 검색 필터로 채널을 찾는다 (키 · 서버 불필요).
class ExplodeChannelSearcher implements ChannelSearcher {
  @override
  Future<List<ChannelHit>> search(String query) async {
    final yt = YoutubeExplode();
    try {
      final list = await yt.search.searchContent(
        query,
        filter: TypeFilters.channel,
      );
      return [
        for (final r in list)
          if (r is SearchChannel)
            ChannelHit(
              id: r.id.value,
              name: r.name,
              description: r.description,
              thumbnailUrl: _thumbnail(r.thumbnails),
              videoCount: r.videoCount,
            ),
      ];
    } finally {
      yt.close();
    }
  }

  @override
  Future<ChannelDetails> details(String channelId) async {
    final yt = YoutubeExplode();
    try {
      final c = await yt.channels.get(channelId);
      var banner = c.bannerUrl.isEmpty ? null : c.bannerUrl;
      var subscribers = c.subscribersCount;
      // 라이브러리가 유튜브의 새 채널 페이지 모양에서 배너 · 구독자 수를 못 읽는 일이 있어 직접 읽어 채운다.
      if (banner == null || subscribers == null) {
        final html = await _channelPage(channelId);
        if (html != null) {
          banner ??= parseBannerUrl(html);
          subscribers ??= parseSubscriberCount(html);
        }
      }
      return ChannelDetails(
        bannerUrl: banner,
        logoUrl: c.logoUrl.isEmpty ? null : c.logoUrl,
        subscriberCount: subscribers,
      );
    } finally {
      yt.close();
    }
  }

  static Future<String?> _channelPage(String channelId) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(
        Uri.parse('https://www.youtube.com/channel/$channelId'),
      );
      req.headers
        ..set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Linux; Android 14)')
        ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.8')
        ..set(HttpHeaders.cookieHeader, 'CONSENT=YES+1; SOCS=CAI');
      final res = await req.close().timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      return await res.transform(utf8.decoder).join();
    } on Exception {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// 채널 페이지의 `imageBannerViewModel`에서 첫 배너 이미지 주소를 읽는다 (없으면 null).
  static String? parseBannerUrl(String html) {
    final m = _banner.firstMatch(html);
    if (m == null) return null;
    return m
        .group(1)!
        .replaceAllMapped(
          RegExp(r'\\x([0-9a-fA-F]{2})'),
          (x) => String.fromCharCode(int.parse(x[1]!, radix: 16)),
        )
        .replaceAll(r'\/', '/');
  }

  /// 페이지 안의 데이터는 `\x22`처럼 이스케이프돼 있다. 이름이 나열만 된 앞쪽 글은 주소가 없어 건너뛴다.
  static final _banner = RegExp(
    r'imageBannerViewModel[^h]{0,120}(https:\\?/\\?/yt3\.googleusercontent\.com(?:[^"\\]|(?!\\x22)\\x[0-9a-fA-F]{2}|\\/)*)',
  );

  /// "1.91M subscribers" 같은 글에서 구독자 수를 읽는다 (없으면 null).
  static int? parseSubscriberCount(String html) {
    final m = RegExp(r'([\d.,]+)\s*([KMB]?)\s+subscribers').firstMatch(html);
    if (m == null) return null;
    final n = double.tryParse(m.group(1)!.replaceAll(',', ''));
    if (n == null) return null;
    final unit = switch (m.group(2)) {
      'K' => 1e3,
      'M' => 1e6,
      'B' => 1e9,
      _ => 1.0,
    };
    return (n * unit).round();
  }

  /// 가장 큰 이미지. 주소가 `//`로 시작하면 https를 붙인다.
  static String? _thumbnail(List<Thumbnail> thumbnails) {
    if (thumbnails.isEmpty) return null;
    final url = thumbnails.last.url;
    return url.hasScheme ? url.toString() : 'https:$url';
  }
}
