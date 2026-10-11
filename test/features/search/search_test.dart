import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/search/data/engine/local_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/routing_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/server_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/search_sort.dart';
import 'package:music_download_play_app/features/search/domain/entities/search_source.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/search_cubit.dart';

import '../../helpers/fakes.dart';

MediaHit _hit(String id, [List<String> categories = const []]) => MediaHit(
  id: id,
  title: 'Title $id',
  url: 'https://example.com/$id',
  categories: categories,
);

SearchCubit _cubit(FakeDownloaderEngine e) =>
    SearchCubit(SearchTracks(e), FetchMediaInfo(e));

void main() {
  group('SearchCubit', () {
    test('키워드 검색: 결과를 담고 더 보기로 다음 쪽을 잇는다', () async {
      final engine = FakeDownloaderEngine(
        pages: [
          SearchPage(items: [_hit('a'), _hit('b')], hasNext: true),
          SearchPage(items: [_hit('b'), _hit('c')], hasNext: false),
        ],
      );
      final cubit = _cubit(engine);
      await cubit.submit('  아이유 ', SearchSource.soundcloud);
      expect(cubit.state.status, SearchStatus.loaded);
      expect(cubit.state.items.map((h) => h.id), ['a', 'b']);
      expect(engine.searches.single, ('아이유', SearchSource.soundcloud, 0));

      await cubit.loadMore();
      expect(cubit.state.items.map((h) => h.id), ['a', 'b', 'c']); // 중복 b 제외
      expect(cubit.state.hasNext, isFalse);
      expect(engine.searches.last.$3, 1);
    });

    test('검색 결과의 곡마다 상세 정보를 뒤에서 읽지 않는다', () async {
      final engine = FakeDownloaderEngine(
        pages: [
          SearchPage(items: [_hit('a'), _hit('b'), _hit('c')], hasNext: false),
        ],
        infoByUrl: {
          'https://example.com/a': VideoInfo(_hit('a', ['Music'])),
        },
      );
      final cubit = _cubit(engine);
      await cubit.submit('q', SearchSource.youtube);
      await pumpEventQueue();
      expect(cubit.state.items.length, 3);
      expect(engine.infos, isEmpty);
    });

    test('최신순은 날짜 순으로 다시 찾고, 벗어나면 관련도 순으로 다시 찾는다', () async {
      final engine = FakeDownloaderEngine(
        pages: [
          SearchPage(items: [_hit('a'), _hit('b')], hasNext: true),
          SearchPage(items: [_hit('c')], hasNext: false),
        ],
      );
      final cubit = _cubit(engine);
      await cubit.submit('q', SearchSource.youtube);
      expect(engine.newestFlags, [false]);
      expect(cubit.state.keyword, isTrue);

      await cubit.selectSort(SearchSort.newest);
      expect(engine.newestFlags, [false, true]);
      expect(cubit.state.sort, SearchSort.newest);
      expect(cubit.state.status, SearchStatus.loaded);

      await cubit.loadMore(); // 다음 쪽도 날짜 순으로
      expect(engine.newestFlags.last, isTrue);

      await cubit.selectSort(SearchSort.shortest); // 받아 온 안에서만: 다시 찾지 않음
      expect(engine.newestFlags.length, 3);

      await cubit.selectSort(SearchSort.relevance); // 최신순에서 벗어남
      expect(engine.newestFlags.last, isFalse);
      expect(engine.newestFlags.length, 4);
    });

    test('URL로 불러온 목록에는 최신순을 쓸 수 없다 (다시 찾지 않는다)', () async {
      final engine = FakeDownloaderEngine(
        info: PlaylistInfo(title: 'L', entries: [_hit('x'), _hit('y')]),
      );
      final cubit = _cubit(engine);
      await cubit.submit(
        'https://youtube.com/playlist?list=1',
        SearchSource.youtube,
      );
      expect(cubit.state.keyword, isFalse);
      await cubit.selectSort(SearchSort.newest);
      expect(engine.searches, isEmpty);
    });

    test('정렬: 인기순은 목록의 조회수 많은 순 (모르는 곡은 맨 뒤)', () async {
      MediaHit hit(String id, int? views) => MediaHit(
        id: id,
        title: 'T$id',
        url: 'https://example.com/$id',
        viewCount: views,
      );
      final engine = FakeDownloaderEngine(
        pages: [
          SearchPage(
            items: [hit('a', 10), hit('b', null), hit('c', 500)],
            hasNext: false,
          ),
        ],
      );
      final cubit = _cubit(engine);
      await cubit.submit('q', SearchSource.youtube);
      cubit.selectSort(SearchSort.popular);
      expect(cubit.state.visibleItems.map((h) => h.id), ['c', 'a', 'b']);
      expect(engine.searches.length, 1); // 다시 찾지 않는다
    });

    test('정렬: 짧은 순 · 긴 순 · 제목순 (길이를 모르는 곡은 맨 뒤)', () async {
      MediaHit hit(String id, String title, int? sec) => MediaHit(
        id: id,
        title: title,
        url: 'https://example.com/$id',
        duration: sec == null ? null : Duration(seconds: sec),
      );
      final engine = FakeDownloaderEngine(
        pages: [
          SearchPage(
            items: [
              hit('a', 'b song', 200),
              hit('b', 'A song', null),
              hit('c', 'c song', 100),
            ],
            hasNext: false,
          ),
        ],
      );
      final cubit = _cubit(engine);
      await cubit.submit('q', SearchSource.youtube);
      await pumpEventQueue();
      List<String> ids() => cubit.state.visibleItems.map((h) => h.id).toList();

      expect(ids(), ['a', 'b', 'c']); // 관련도순 = 찾은 순서
      cubit.selectSort(SearchSort.shortest);
      expect(ids(), ['c', 'a', 'b']);
      cubit.selectSort(SearchSort.longest);
      expect(ids(), ['a', 'c', 'b']);
      cubit.selectSort(SearchSort.title);
      expect(ids(), ['b', 'a', 'c']);
    });

    test('곡 하나 주소는 이미 분류가 있어 다시 읽지 않는다', () async {
      final engine = FakeDownloaderEngine(
        info: VideoInfo(_hit('v', ['Music'])),
      );
      final cubit = _cubit(engine);
      await cubit.submit('https://youtu.be/v', SearchSource.youtube);
      await pumpEventQueue();
      expect(engine.infos, ['https://youtu.be/v']);
      expect(cubit.state.items.single.categories, ['Music']);
    });

    test('URL이면 정보를 불러온다 (곡 하나 · 재생목록)', () async {
      final video = FakeDownloaderEngine(info: VideoInfo(_hit('v')));
      final c1 = _cubit(video);
      await c1.submit('https://youtu.be/v', SearchSource.youtube);
      expect(video.infos, ['https://youtu.be/v']);
      expect(video.searches, isEmpty);
      expect(c1.state.items.single.id, 'v');
      expect(c1.state.playlistTitle, isNull);

      final list = FakeDownloaderEngine(
        info: PlaylistInfo(title: '내 목록', entries: [_hit('x'), _hit('y')]),
      );
      final c2 = _cubit(list);
      await c2.submit(
        'https://youtube.com/playlist?list=1',
        SearchSource.soundcloud,
      );
      expect(c2.state.playlistTitle, '내 목록');
      expect(c2.state.items, hasLength(2));
    });

    test('실패는 까닭과 함께 failed로, 빈 입력은 idle로', () async {
      final cubit = _cubit(
        FakeDownloaderEngine(
          error: const EngineException(EngineFailure.network),
        ),
      );
      await cubit.submit('x', SearchSource.youtube);
      expect(cubit.state.status, SearchStatus.failed);
      expect(cubit.state.failure, EngineFailure.network);

      await cubit.submit('  ', SearchSource.youtube);
      expect(cubit.state.status, SearchStatus.idle);
    });
  });

  group('ServerEngine', () {
    test('검색 · 정보 요청과 응답 해석, 토큰 헤더', () async {
      final calls = <Uri>[];
      Map<String, String>? sentHeaders;
      final engine = ServerEngine(
        baseUrl: 'https://s.example/',
        tokenProvider: () async => 'tok',
        get: (uri, headers) async {
          calls.add(uri);
          sentHeaders = headers;
          if (uri.path.endsWith('/search')) {
            return (
              status: 200,
              body: jsonEncode({
                'items': [
                  {
                    'videoId': 'abc',
                    'title': 'T',
                    'uploader': 'U',
                    'durationSec': 215,
                    'thumbnail': 'https://t/x.jpg',
                  },
                ],
                'hasNext': true,
              }),
            );
          }
          return (
            status: 200,
            body: jsonEncode({
              'type': 'video',
              'videoId': 'abc',
              'title': 'T',
              'downloaded': true,
            }),
          );
        },
      );
      final page = await engine.search('아이유', page: 1, size: 10);
      expect(calls.single.path, '/api/v1/search');
      expect(calls.single.queryParameters, {
        'q': '아이유',
        'page': '1',
        'size': '10',
      });
      expect(sentHeaders!['Authorization'], 'Bearer tok');
      expect(page.hasNext, isTrue);
      final hit = page.items.single;
      expect(hit.duration, const Duration(seconds: 215));
      expect(hit.url, 'https://www.youtube.com/watch?v=abc');

      final info = await engine.fetchInfo('https://youtu.be/abc');
      expect(info, isA<VideoInfo>());
      expect((info as VideoInfo).hit.downloaded, isTrue);

      await engine.search('q', source: SearchSource.soundcloud);
      expect(calls.last.queryParameters['source'], 'web');
    });

    test('오류 코드를 EngineFailure로 옮긴다', () async {
      Future<EngineFailure> failure(
        Future<({int status, String body})> Function() get,
      ) async {
        final engine = ServerEngine(baseUrl: 'https://s', get: (_, _) => get());
        try {
          await engine.search('q');
        } on EngineException catch (e) {
          return e.failure;
        }
        fail('던지지 않았다');
      }

      expect(
        await failure(() async => (status: 401, body: '')),
        EngineFailure.unauthorized,
      );
      expect(
        await failure(
          () async => (status: 404, body: '{"code":"X","message":"m"}'),
        ),
        EngineFailure.notFound,
      );
      expect(
        await failure(() async => (status: 500, body: 'oops')),
        EngineFailure.failed,
      );
      expect(
        await failure(() async => throw const SocketException('down')),
        EngineFailure.network,
      );
    });

    test('최신순이면 sort=date를 보낸다', () async {
      final calls = <Uri>[];
      final engine = ServerEngine(
        baseUrl: 'https://s',
        get: (uri, _) async {
          calls.add(uri);
          return (status: 200, body: '{"items":[],"hasNext":false}');
        },
      );
      await engine.search('q');
      await engine.search('q', newest: true);
      expect(calls[0].queryParameters.containsKey('sort'), isFalse);
      expect(calls[1].queryParameters['sort'], 'date');
    });

    test('서버 응답의 categories를 읽는다', () async {
      final engine = ServerEngine(
        baseUrl: 'https://s',
        get: (_, _) async => (
          status: 200,
          body: jsonEncode({
            'videoId': 'v',
            'title': 'T',
            'categories': ['Gaming'],
          }),
        ),
      );
      final info = await engine.fetchInfo('https://x/v');
      expect((info as VideoInfo).hit.categories, ['Gaming']);
    });
  });

  group('LocalEngine', () {
    String line(String id) => jsonEncode({
      'id': id,
      'title': 'T$id',
      'uploader': 'U',
      'duration': 100.0,
      'url': 'https://www.youtube.com/watch?v=$id',
    });

    test('ytsearch로 (page+1)*size개를 받아 해당 쪽만 돌려준다', () async {
      List<String>? args;
      final engine = LocalEngine(
        run: (exe, a) async {
          args = a;
          return (
            exitCode: 0,
            stdout: '${line('a')}\n${line('b')}\n${line('c')}\n',
            stderr: '',
          );
        },
      );
      final page = await engine.search('노래', page: 1, size: 2);
      expect(args!.last, 'ytsearch4:노래');
      expect(page.items.map((h) => h.id), ['c']);
      expect(page.hasNext, isFalse);

      await engine.search('노래', source: SearchSource.soundcloud, size: 1);
      expect(args!.last, 'scsearch1:노래');

      await engine.search('노래', size: 3, newest: true);
      expect(args!.last, 'ytsearchdate3:노래'); // 최신순은 날짜 순 검색
      await engine.search(
        '노래',
        source: SearchSource.soundcloud,
        size: 1,
        newest: true,
      );
      expect(args!.last, 'scsearch1:노래'); // 날짜 순 검색이 없는 사이트는 그대로
      await engine.search('노래', source: SearchSource.niconico, size: 2);
      expect(args!.last, 'nicosearch2:노래');
      await engine.search('노래', source: SearchSource.bilibili, size: 2);
      expect(args!.last, 'bilisearch2:노래');
    });

    test('재생목록 정보를 읽는다', () async {
      final engine = LocalEngine(
        run: (_, _) async => (
          exitCode: 0,
          stdout: jsonEncode({
            '_type': 'playlist',
            'title': 'L',
            'entries': [jsonDecode(line('a'))],
          }),
          stderr: '',
        ),
      );
      final info = await engine.fetchInfo('https://x/list');
      expect(info, isA<PlaylistInfo>());
      expect((info as PlaylistInfo).entries.single.title, 'Ta');
    });

    test('곡 하나를 읽으면 유튜브 분류(categories)가 담긴다', () async {
      final engine = LocalEngine(
        run: (_, _) async => (
          exitCode: 0,
          stdout: jsonEncode({
            'id': 'v',
            'title': 'T',
            'categories': ['Music', ' ', 3],
          }),
          stderr: '',
        ),
      );
      final info = await engine.fetchInfo('https://x/v');
      expect((info as VideoInfo).hit.categories, ['Music']);
    });

    test('목록 검색 결과에는 분류가 없어 빈 목록이다', () async {
      final engine = LocalEngine(
        run: (_, _) async => (
          exitCode: 0,
          stdout: '${jsonEncode({'id': 'a', 'title': 'Ta'})}\n',
          stderr: '',
        ),
      );
      final page = await engine.search('q', size: 1);
      expect(page.items.single.categories, isEmpty);
    });

    test('yt-dlp가 없으면 사용할 수 없다', () async {
      final engine = LocalEngine(
        run: (_, _) async => throw const ProcessException('yt-dlp', []),
      );
      expect(await engine.isAvailable(), isFalse);
      await expectLater(
        engine.search('q'),
        throwsA(
          isA<EngineException>().having(
            (e) => e.failure,
            'failure',
            EngineFailure.unavailable,
          ),
        ),
      );
    });
  });

  group('RoutingDownloaderEngine', () {
    test('로컬 yt-dlp가 있으면 로컬, 없으면 서버, 둘 다 없으면 unavailable', () async {
      final noYtDlp = LocalEngine(
        run: (_, _) async => (exitCode: 1, stdout: '', stderr: ''),
      );
      var serverCalls = 0;
      final server = ServerEngine(
        baseUrl: 'https://s',
        get: (_, _) async {
          serverCalls++;
          return (status: 200, body: '{"items":[],"hasNext":false}');
        },
      );
      await RoutingDownloaderEngine(local: noYtDlp, server: server).search('q');
      expect(serverCalls, 1);

      final withYtDlp = LocalEngine(
        run: (_, _) async => (exitCode: 0, stdout: '', stderr: ''),
      );
      await RoutingDownloaderEngine(
        local: withYtDlp,
        server: server,
      ).search('q');
      expect(serverCalls, 1); // 서버는 부르지 않았다

      await expectLater(
        RoutingDownloaderEngine().search('q'),
        throwsA(isA<EngineException>()),
      );
    });
  });

  group('검색 화면', () {
    Future<void> openSearch(WidgetTester tester) async {
      await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
      await tester.pumpAndSettle();
    }

    testWidgets('입력 후 확인하면 결과가 나오고 받기 버튼을 누르면 받기 팝업이 열린다', (tester) async {
      final engine = FakeDownloaderEngine(
        pages: [
          const SearchPage(
            items: [
              MediaHit(
                id: 'a',
                title: 'Found Song',
                url: 'https://example.com/a',
                uploader: 'Some Artist',
                duration: Duration(minutes: 3, seconds: 5),
              ),
            ],
            hasNext: false,
          ),
        ],
      );
      await setUpTestDependencies(engine: engine);
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(engine.searches.single.$1, 'hello');
      expect(find.text('Found Song'), findsOneWidget);
      expect(find.textContaining('Some Artist'), findsOneWidget);
      // 재생 시간은 채널 이름 옆에 보인다.
      expect(find.textContaining('Some Artist · 3:05'), findsOneWidget);

      await tester.tap(find.byTooltip('Download'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Found Song'), findsOneWidget);
    });

    testWidgets('받은 곡이든 아니든 채널 이름 옆에 전체 길이가 보인다', (tester) async {
      final engine = FakeDownloaderEngine(
        pages: [
          const SearchPage(
            items: [
              MediaHit(
                id: 'a',
                title: 'Have It',
                url: 'https://example.com/a',
                uploader: 'Chan',
                duration: Duration(minutes: 3, seconds: 5),
                downloaded: true,
              ),
              MediaHit(
                id: 'b',
                title: 'New One',
                url: 'https://example.com/b',
                uploader: 'Chan',
                duration: Duration(minutes: 4, seconds: 1),
              ),
            ],
            hasNext: false,
          ),
        ],
      );
      await setUpTestDependencies(engine: engine);
      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'x');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.textContaining('Chan · 3:05'), findsOneWidget);
      expect(find.textContaining('Chan · 4:01'), findsOneWidget);
    });

    testWidgets('정렬 메뉴에서 최신순을 고르면 날짜 순으로 다시 찾는다', (tester) async {
      final engine = FakeDownloaderEngine(
        pages: [
          SearchPage(items: [_hit('a'), _hit('b')], hasNext: false),
        ],
      );
      await setUpTestDependencies(engine: engine);
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(engine.newestFlags, [false]);

      await tester.tap(find.text('Relevance')); // 정렬 메뉴를 연다
      await tester.pumpAndSettle();
      await tester.tap(find.text('Newest'));
      await tester.pumpAndSettle();
      expect(engine.newestFlags, [false, true]);
      expect(find.text('Title a'), findsOneWidget);
    });

    testWidgets('아래로 내려가 끝에 닿으면 다음 결과가 자동으로 붙는다', (tester) async {
      final engine = FakeDownloaderEngine(
        pages: [
          SearchPage(items: [_hit('a'), _hit('b')], hasNext: true),
          SearchPage(items: [_hit('c')], hasNext: false),
        ],
        infoByUrl: {},
      );
      await setUpTestDependencies(engine: engine);
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(engine.searches.map((e) => e.$3), [0, 1]); // 버튼 없이 이어 붙음
      expect(find.text('Title c'), findsOneWidget);
    });

    testWidgets('쓸 수 있는 엔진이 없으면 안내를 보여 준다', (tester) async {
      await setUpTestDependencies(
        engine: FakeDownloaderEngine(
          error: const EngineException(EngineFailure.unavailable),
        ),
      );
      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'x');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('No engine available'), findsOneWidget);
    });
  });
}
