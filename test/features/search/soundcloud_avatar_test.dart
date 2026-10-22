import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/data/engine/soundcloud_avatar_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';

import '../../helpers/fakes.dart';

const _html = '''
<html><head>
<meta property="og:title" content="Artist">
<meta property="og:image" content="https://i1.sndcdn.com/avatars-000-abc-large.jpg?x=1&amp;y=2">
</head></html>''';

void main() {
  test('아티스트 페이지의 og:image를 큰 프로필 이미지로 읽는다', () {
    expect(
      soundcloudAvatarFromHtml(_html),
      'https://i1.sndcdn.com/avatars-000-abc-t500x500.jpg?x=1&y=2',
    );
    expect(soundcloudAvatarFromHtml('<html></html>'), isNull);
  });

  test('SoundCloud 채널 이미지가 비면 페이지에서 채우고, 구독자 수는 그대로 둔다', () async {
    final inner = FakeDownloaderEngine(
      channel: const ChannelInfo(subscriberCount: 12),
    );
    final engine = SoundcloudAvatarEngine(inner, readPage: (_) async => _html);
    final info = await engine.fetchChannel('https://soundcloud.com/artist');
    expect(info.thumbnailUrl, contains('t500x500'));
    expect(info.subscriberCount, 12);
  });

  test('안쪽 엔진이 못 읽어도(서버 모드) 페이지에서 이미지를 읽는다', () async {
    // channel이 없으면 fetchChannel은 unavailable을 던진다.
    final inner = FakeDownloaderEngine();
    final engine = SoundcloudAvatarEngine(inner, readPage: (_) async => _html);
    final info = await engine.fetchChannel('https://soundcloud.com/artist');
    expect(info.thumbnailUrl, isNotNull);
  });

  test('유튜브 채널은 그대로 안쪽 엔진에 맡긴다', () async {
    final inner = FakeDownloaderEngine(
      channel: const ChannelInfo(thumbnailUrl: 'https://yt/a.jpg'),
    );
    final engine = SoundcloudAvatarEngine(
      inner,
      readPage: (_) async => fail('페이지를 읽으면 안 된다'),
    );
    final info = await engine.fetchChannel('https://www.youtube.com/@a');
    expect(info.thumbnailUrl, 'https://yt/a.jpg');
  });
}
