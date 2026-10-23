import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/subscriptions/data/datasources/explode_channel_searcher.dart';

void main() {
  // 유튜브 채널 페이지 안의 데이터는 \x22 같은 이스케이프로 들어 있다 (주소는 예시).
  const page =
      r'names \x22imageBannerViewModel\x22,\x22dynamicTextViewModel\x22 ... '
      r'imageBannerViewModel\x22:\x7b\x22image\x22:\x7b\x22sources\x22:\x5b\x7b'
      r'\x22url\x22:\x22https:\/\/yt3.googleusercontent.com\/abc\x3dw1060-k\x22,'
      r'\x22width\x22:1060\x7d \x22content\x22:\x22@x • 1.91M subscribers\x22';

  test('채널 페이지에서 배너 주소를 읽는다', () {
    expect(
      ExplodeChannelSearcher.parseBannerUrl(page),
      'https://yt3.googleusercontent.com/abc=w1060-k',
    );
  });

  test('배너가 없으면 null', () {
    expect(ExplodeChannelSearcher.parseBannerUrl('<html></html>'), isNull);
  });

  test('채널 소개 전체를 읽고, 줄바꿈 · 따옴표를 풀어 준다', () {
    const html =
        r'"channelMetadataRenderer":{"title":"Lofi \"Girl\"","description":'
        r'"첫 줄\n둘째 줄 \"인용\" 🌇\n","rssUrl":"https://example.com"}';
    expect(
      ExplodeChannelSearcher.parseDescription(html),
      '첫 줄\n둘째 줄 "인용" \u{1F307}',
    );
    expect(ExplodeChannelSearcher.parseDescription('<html></html>'), isNull);
    expect(
      ExplodeChannelSearcher.parseDescription(
        r'"channelMetadataRenderer":{"title":"x","description":"   "}',
      ),
      isNull,
    );
  });

  test('구독자 수 글을 숫자로 읽는다', () {
    expect(ExplodeChannelSearcher.parseSubscriberCount(page), 1910000);
    expect(ExplodeChannelSearcher.parseSubscriberCount('532 subscribers'), 532);
    expect(ExplodeChannelSearcher.parseSubscriberCount('nothing'), isNull);
  });
}
