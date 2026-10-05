import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
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
);

MediaDetailCubit _cubit(FakeDownloaderEngine e, FakeLinkOpener o) =>
    MediaDetailCubit(_listHit, FetchMediaInfo(e), OpenLink(o));

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
      await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Song options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      return opener;
    }

    testWidgets('옵션 메뉴의 상세 보기에서 채널 · 조회수 · 설명이 보인다', (tester) async {
      await openDetail(tester);

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Chan'), findsOneWidget);
      expect(find.text('View channel'), findsOneWidget);
      expect(find.text('3:05'), findsOneWidget);
      expect(find.textContaining('views'), findsOneWidget);
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

    testWidgets('받기를 누르면 받기 팝업이 열린다', (tester) async {
      await openDetail(tester);

      await tester.tap(find.byKey(const ValueKey('detail-download')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Song'), findsOneWidget);
    });
  });
}
