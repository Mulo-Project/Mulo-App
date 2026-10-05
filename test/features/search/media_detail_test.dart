import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/search/data/engine/local_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/server_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/media_detail_cubit.dart';
import 'package:music_download_play_app/features/search/presentation/screens/media_detail_screen.dart';

import '../../helpers/fakes.dart';

const _listHit = MediaHit(
  id: 'v',
  title: 'Song',
  url: 'https://www.youtube.com/watch?v=v',
  uploader: 'Chan',
  duration: Duration(minutes: 3, seconds: 5),
);

final _fullHit = MediaHit(
  id: 'v',
  title: 'Song',
  url: 'https://www.youtube.com/watch?v=v',
  uploader: 'Chan',
  categories: const ['Music'],
  channelUrl: 'https://www.youtube.com/@chan',
  viewCount: 12345,
  uploadedAt: DateTime(2024, 1, 31),
  description: 'Line one\nLine two',
  likeCount: 4321,
  subscriberCount: 2500000,
  channelThumbnailUrl: 'https://img/avatar.png',
);

MediaDetailCubit _cubit(FakeDownloaderEngine e, FakeLinkOpener o) =>
    MediaDetailCubit(
      _listHit,
      FetchMediaInfo(e),
      FetchChannelInfo(e),
      OpenLink(o),
    );

void main() {
  group('엔진 응답의 상세 정보', () {
    test('LocalEngine: 채널 주소 · 조회수 · 올린 날 · 설명을 읽는다', () async {
      final engine = LocalEngine(
        run: (_, _) async => (
          exitCode: 0,
          stdout: jsonEncode({
            'id': 'v',
            'title': 'T',
            'channel_url': 'https://www.youtube.com/@chan',
            'view_count': 12345,
            'upload_date': '20240131',
            'description': '  hello  ',
          }),
          stderr: '',
        ),
      );
      final hit = ((await engine.fetchInfo('https://x/v')) as VideoInfo).hit;
      expect(hit.channelUrl, 'https://www.youtube.com/@chan');
      expect(hit.viewCount, 12345);
      expect(hit.uploadedAt, DateTime(2024, 1, 31));
      expect(hit.description, 'hello');
    });

    test('LocalEngine: 없는 칸은 비어 있다', () async {
      final engine = LocalEngine(
        run: (_, _) async => (
          exitCode: 0,
          stdout: jsonEncode({'id': 'v', 'title': 'T', 'upload_date': 'x'}),
          stderr: '',
        ),
      );
      final hit = ((await engine.fetchInfo('https://x/v')) as VideoInfo).hit;
      expect(hit.channelUrl, isNull);
      expect(hit.viewCount, isNull);
      expect(hit.uploadedAt, isNull);
      expect(hit.description, '');
    });

    test('LocalEngine: 좋아요 · 구독자 수를 읽는다', () async {
      final engine = LocalEngine(
        run: (_, _) async => (
          exitCode: 0,
          stdout: jsonEncode({
            'id': 'v',
            'title': 'T',
            'like_count': 10,
            'channel_follower_count': 2500,
          }),
          stderr: '',
        ),
      );
      final hit = ((await engine.fetchInfo('https://x/v')) as VideoInfo).hit;
      expect(hit.likeCount, 10);
      expect(hit.subscriberCount, 2500);
    });

    test('LocalEngine.fetchChannel: 채널 이미지(배너 제외)와 구독자 수', () async {
      List<String>? args;
      final engine = LocalEngine(
        run: (_, a) async {
          args = a;
          return (
            exitCode: 0,
            stdout: jsonEncode({
              'channel_follower_count': 2500000,
              'thumbnails': [
                {'id': '0', 'url': 'https://img/banner.jpg'},
                {'id': 'avatar_uncropped', 'url': 'https://img/avatar.jpg'},
              ],
            }),
            stderr: '',
          );
        },
      );
      final channel = await engine.fetchChannel('https://www.youtube.com/@c');
      expect(channel.thumbnailUrl, 'https://img/avatar.jpg');
      expect(channel.subscriberCount, 2500000);
      expect(args, containsAllInOrder(['--playlist-items', '0']));
    });

    test('ServerEngine: 채널 조회는 없고 곡 정보의 구독자 · 이미지를 읽는다', () async {
      final engine = ServerEngine(
        baseUrl: 'https://s',
        get: (_, _) async => (
          status: 200,
          body: jsonEncode({
            'videoId': 'v',
            'title': 'T',
            'likeCount': 3,
            'subscriberCount': 4,
            'channelThumbnail': 'https://img/c.png',
          }),
        ),
      );
      final hit = ((await engine.fetchInfo('https://x/v')) as VideoInfo).hit;
      expect([hit.likeCount, hit.subscriberCount], [3, 4]);
      expect(hit.channelThumbnailUrl, 'https://img/c.png');
      expect(
        () => engine.fetchChannel('https://c'),
        throwsA(isA<EngineException>()),
      );
    });

    test('ServerEngine: 같은 정보를 읽는다', () async {
      final engine = ServerEngine(
        baseUrl: 'https://s',
        get: (_, _) async => (
          status: 200,
          body: jsonEncode({
            'videoId': 'v',
            'title': 'T',
            'channelUrl': 'https://c',
            'viewCount': 7,
            'uploadDate': '2024-01-31',
            'description': 'd',
          }),
        ),
      );
      final hit = ((await engine.fetchInfo('https://x/v')) as VideoInfo).hit;
      expect(hit.channelUrl, 'https://c');
      expect(hit.viewCount, 7);
      expect(hit.uploadedAt, DateTime(2024, 1, 31));
      expect(hit.description, 'd');
    });
  });

  test('MediaHit.filledFrom: 알던 것은 두고 비어 있는 것만 채운다', () {
    final merged = _listHit.filledFrom(_fullHit);
    expect(merged.duration, const Duration(minutes: 3, seconds: 5));
    expect(merged.channelUrl, _fullHit.channelUrl);
    expect(merged.viewCount, 12345);
    expect(merged.categories, ['Music']);
    expect(merged.title, 'Song');
  });

  group('공동 작업자(여러 채널이 함께 올린 영상)', () {
    // 목록에서는 이름이 합쳐지고 채널 주소가 없다. 자세히 읽으면 대표 채널이 나온다.
    const listed = MediaHit(
      id: 'c',
      title: 'Collab',
      url: 'https://www.youtube.com/watch?v=c',
      uploader: 'Sauce + and William Osman 2',
    );
    const full = MediaHit(
      id: 'c',
      title: 'Collab',
      url: 'https://www.youtube.com/watch?v=c',
      uploader: 'Sauce +',
      channelUrl: 'https://www.youtube.com/channel/UC2Ei',
      creators: ['Sauce +', 'William Osman 2'],
    );

    test('filledFrom은 합쳐진 이름 대신 대표 채널 이름을 쓴다', () {
      final merged = listed.filledFrom(full);
      expect(merged.uploader, 'Sauce +');
      expect(merged.channelUrl, 'https://www.youtube.com/channel/UC2Ei');
      expect(merged.creators, ['Sauce +', 'William Osman 2']);
    });

    test('공동 작업이 아니면 목록의 이름을 그대로 둔다', () {
      const solo = MediaHit(id: 's', title: 'S', url: 'u', uploader: 'Chan');
      final merged = solo.filledFrom(
        const MediaHit(
          id: 's',
          title: 'S',
          url: 'u',
          uploader: 'Chan (full)',
          creators: ['Chan'],
        ),
      );
      expect(merged.uploader, 'Chan');
    });

    test('LocalEngine이 creators를 읽는다', () async {
      final engine = LocalEngine(
        run: (_, _) async => (
          exitCode: 0,
          stdout: jsonEncode({
            'id': 'c',
            'title': 'Collab',
            'channel': 'Sauce +',
            'channel_url': 'https://www.youtube.com/channel/UC2Ei',
            'creators': ['Sauce +', ' ', 'William Osman 2'],
          }),
          stderr: '',
        ),
      );
      final hit = ((await engine.fetchInfo('https://x/c')) as VideoInfo).hit;
      expect(hit.creators, ['Sauce +', 'William Osman 2']);
    });

    test('상세는 대표 채널의 주소로 채널 정보를 읽고 이름도 대표 채널로 바뀐다', () async {
      final engine = FakeDownloaderEngine(
        info: const VideoInfo(full),
        channel: const ChannelInfo(subscriberCount: 243),
      );
      final cubit = MediaDetailCubit(
        listed,
        FetchMediaInfo(engine),
        FetchChannelInfo(engine),
        OpenLink(FakeLinkOpener()),
      );
      await cubit.load();
      expect(engine.channels, ['https://www.youtube.com/channel/UC2Ei']);
      expect(cubit.state.hit.uploader, 'Sauce +');
      expect(cubit.state.hit.subscriberCount, 243);
    });
  });

  group('MediaDetailCubit', () {
    test('곡 정보를 읽어 빈 정보를 채운다', () async {
      final engine = FakeDownloaderEngine(info: VideoInfo(_fullHit));
      final cubit = _cubit(engine, FakeLinkOpener());
      await cubit.load();
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.hit.channelUrl, _fullHit.channelUrl);
      expect(cubit.state.hit.duration, _listHit.duration);
      expect(engine.infos, [_listHit.url]);
    });

    test('못 읽어도 알던 정보를 그대로 둔다', () async {
      final engine = FakeDownloaderEngine(
        error: const EngineException(EngineFailure.network),
      );
      final cubit = _cubit(engine, FakeLinkOpener());
      await cubit.load();
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.hit, _listHit);
    });

    test('채널 이미지 · 구독자 수는 채널 정보를 따로 읽어 채운다', () async {
      final engine = FakeDownloaderEngine(
        info: VideoInfo(
          MediaHit(
            id: 'v',
            title: 'Song',
            url: _listHit.url,
            channelUrl: 'https://www.youtube.com/@chan',
          ),
        ),
        channel: const ChannelInfo(
          thumbnailUrl: 'https://img/a.png',
          subscriberCount: 99,
        ),
      );
      final cubit = _cubit(engine, FakeLinkOpener());
      await cubit.load();
      expect(engine.channels, ['https://www.youtube.com/@chan']);
      expect(cubit.state.hit.channelThumbnailUrl, 'https://img/a.png');
      expect(cubit.state.hit.subscriberCount, 99);
    });

    test('채널 정보를 못 읽어도 나머지는 그대로다', () async {
      final engine = FakeDownloaderEngine(
        info: VideoInfo(
          MediaHit(
            id: 'v',
            title: 'Song',
            url: _listHit.url,
            channelUrl: 'https://c',
            viewCount: 5,
          ),
        ),
      );
      final cubit = _cubit(engine, FakeLinkOpener());
      await cubit.load();
      expect(cubit.state.hit.viewCount, 5);
      expect(cubit.state.hit.channelThumbnailUrl, isNull);
    });

    test('곡 정보에 채널 정보가 이미 있으면 다시 읽지 않는다', () async {
      final engine = FakeDownloaderEngine(info: VideoInfo(_fullHit));
      final cubit = _cubit(engine, FakeLinkOpener());
      await cubit.load();
      expect(engine.channels, isEmpty);
    });

    test('open은 링크 열기에 맡기고 결과를 돌려준다', () async {
      final opener = FakeLinkOpener(opens: false);
      final cubit = _cubit(FakeDownloaderEngine(), opener);
      expect(await cubit.open('https://c'), isFalse);
      expect(opener.opened, ['https://c']);
    });
  });

  test('isYoutubeUrl', () {
    expect(isYoutubeUrl('https://www.youtube.com/watch?v=a'), isTrue);
    expect(isYoutubeUrl('https://youtu.be/a'), isTrue);
    expect(isYoutubeUrl('https://music.youtube.com/watch?v=a'), isTrue);
    expect(isYoutubeUrl('https://soundcloud.com/a'), isFalse);
    expect(isYoutubeUrl('https://notyoutube.com/a'), isFalse);
  });

  group('상세 보기 화면', () {
    Future<void> openSearchResult(WidgetTester tester) async {
      await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    Future<FakeLinkOpener> openDetail(
      WidgetTester tester, {
      bool opens = true,
    }) async {
      // 설명까지 한 화면에 보이도록 세로를 늘린다.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final opener = FakeLinkOpener(opens: opens);
      final engine = FakeDownloaderEngine(
        pages: const [
          SearchPage(items: [_listHit], hasNext: false),
        ],
        info: VideoInfo(_fullHit),
      );
      await setUpTestDependencies(engine: engine, linkOpener: opener);
      await openSearchResult(tester);
      await tester.tap(find.text('Song'));
      await tester.pumpAndSettle();
      return opener;
    }

    testWidgets('곡을 누르면 상세 보기에서 채널 · 구독자 · 좋아요 · 조회수 · 설명이 보인다', (
      tester,
    ) async {
      await openDetail(tester);

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Chan'), findsOneWidget);
      expect(find.text('View channel'), findsOneWidget);
      expect(find.text('3:05'), findsOneWidget);
      expect(find.textContaining('views'), findsOneWidget);
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('4.32K'), findsOneWidget);
      expect(find.text('2.5M subscribers'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.textContaining('Line one'), findsOneWidget);
    });

    testWidgets('영상 보기 · 채널 보기는 해당 주소를 연다', (tester) async {
      final opener = await openDetail(tester);

      await tester.tap(find.byKey(const ValueKey('detail-watch')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View channel'));
      await tester.pumpAndSettle();

      expect(opener.opened, [_fullHit.url, _fullHit.channelUrl]);
    });

    testWidgets('열 수 없으면 안내한다', (tester) async {
      await openDetail(tester, opens: false);

      await tester.tap(find.byKey(const ValueKey('detail-watch')));
      await tester.pumpAndSettle();
      expect(find.text('No app can open this link.'), findsOneWidget);
    });

    testWidgets('길게 누르면 옵션 메뉴가 뜨고 상세 보기를 고를 수 있다', (tester) async {
      await openSearchResult(tester);
      await tester.longPress(find.text('Song'));
      await tester.pumpAndSettle();
      expect(find.text('View details'), findsOneWidget);
      expect(find.text('Details'), findsNothing);

      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('긴 설명만 더 보기가 나오고 누르면 펼쳐진다', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final long = [for (var i = 1; i <= 12; i++) 'Line $i'].join('\n');
      final engine = FakeDownloaderEngine(
        pages: const [
          SearchPage(items: [_listHit], hasNext: false),
        ],
        info: VideoInfo(
          MediaHit(
            id: 'v',
            title: 'Song',
            url: _listHit.url,
            description: long,
          ),
        ),
      );
      await setUpTestDependencies(engine: engine, linkOpener: FakeLinkOpener());
      await openSearchResult(tester);
      await tester.tap(find.text('Song'));
      await tester.pumpAndSettle();

      const toggle = ValueKey('detail-description-toggle');
      expect(find.text('Show more'), findsOneWidget);
      expect(find.textContaining('Line 12'), findsOneWidget); // 잘려도 글은 있다
      final collapsed = tester.getSize(find.textContaining('Line 1')).height;

      await tester.tap(find.byKey(toggle));
      await tester.pumpAndSettle();
      expect(find.text('Show less'), findsOneWidget);
      expect(
        tester.getSize(find.textContaining('Line 1')).height,
        greaterThan(collapsed),
      );

      await tester.tap(find.byKey(toggle));
      await tester.pumpAndSettle();
      expect(find.text('Show more'), findsOneWidget);
    });

    testWidgets('긴 채널 이름은 잘리지 않고 흐르는 글자로 보인다', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const name =
          'A very very long channel name that cannot fit in one line at all';
      const hit = MediaHit(
        id: 'v',
        title: 'Song',
        url: 'https://www.youtube.com/watch?v=v',
        uploader: name,
      );
      final engine = FakeDownloaderEngine(
        pages: const [
          SearchPage(items: [hit], hasNext: false),
        ],
        info: const VideoInfo(hit),
      );
      await setUpTestDependencies(engine: engine, linkOpener: FakeLinkOpener());
      await openSearchResult(tester);
      await tester.tap(find.text('Song'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byWidgetPredicate((w) => w is MarqueeText && w.text == name),
        findsOneWidget,
      );
      expect(find.byType(ShaderMask), findsWidgets); // 넘치면 흐른다
      // 화면을 정리해 반복 애니메이션을 멈춘다.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('더 보기 버튼은 가운데에 놓인다', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final long = [for (var i = 1; i <= 12; i++) 'Line $i'].join('\n');
      final engine = FakeDownloaderEngine(
        pages: const [
          SearchPage(items: [_listHit], hasNext: false),
        ],
        info: VideoInfo(
          MediaHit(
            id: 'v',
            title: 'Song',
            url: _listHit.url,
            description: long,
          ),
        ),
      );
      await setUpTestDependencies(engine: engine, linkOpener: FakeLinkOpener());
      await openSearchResult(tester);
      await tester.tap(find.text('Song'));
      await tester.pumpAndSettle();

      final center = tester.getCenter(
        find.byKey(const ValueKey('detail-description-toggle')),
      );
      expect(center.dx, closeTo(400, 1));
    });

    testWidgets('공동 작업 영상은 대표 채널과 나머지 공동 작업자를 보여 준다', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const listed = MediaHit(
        id: 'c',
        title: 'Collab',
        url: 'https://www.youtube.com/watch?v=c',
        uploader: 'Sauce + and William Osman 2',
      );
      const full = MediaHit(
        id: 'c',
        title: 'Collab',
        url: 'https://www.youtube.com/watch?v=c',
        uploader: 'Sauce +',
        channelUrl: 'https://www.youtube.com/channel/UC2Ei',
        creators: ['Sauce +', 'William Osman 2'],
      );
      final engine = FakeDownloaderEngine(
        pages: const [
          SearchPage(items: [listed], hasNext: false),
        ],
        info: const VideoInfo(full),
        channel: const ChannelInfo(subscriberCount: 243),
      );
      await setUpTestDependencies(engine: engine, linkOpener: FakeLinkOpener());
      await openSearchResult(tester);
      await tester.tap(find.text('Collab'));
      await tester.pumpAndSettle();

      expect(find.text('Sauce +'), findsOneWidget); // 대표 채널
      expect(find.text('243 subscribers'), findsOneWidget);
      expect(find.text('Collaborators'), findsOneWidget);
      expect(find.text('William Osman 2'), findsOneWidget);
      expect(find.text('Sauce + and William Osman 2'), findsNothing);
    });

    testWidgets('짧은 설명에는 더 보기 버튼이 없다', (tester) async {
      await openDetail(tester);
      expect(
        find.byKey(const ValueKey('detail-description-toggle')),
        findsNothing,
      );
    });

    testWidgets('받기를 누르면 받기 팝업이 열린다', (tester) async {
      await openDetail(tester);

      await tester.tap(find.byKey(const ValueKey('detail-download')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Song'), findsOneWidget);
    });
  });
}
