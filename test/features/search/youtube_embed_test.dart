import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/presentation/screens/media_detail_screen.dart';
import 'package:music_download_play_app/features/search/presentation/widgets/youtube_embed.dart';
import 'package:music_download_play_app/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';

const _yt = MediaHit(
  id: 'dQw4w9WgXcQ',
  title: 'Song',
  url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  uploader: 'Chan',
);

void main() {
  group('임베드 페이지', () {
    test('영상 id를 담은 IFrame API 페이지를 만든다', () {
      final html = youtubeEmbedHtml('dQw4w9WgXcQ');
      expect(html, contains("videoId: 'dQw4w9WgXcQ'"));
      expect(html, contains('https://www.youtube.com/iframe_api'));
      expect(html, contains("Player.postMessage('error:'"));
      expect(html, contains("Player.postMessage('ready')"));
    });

    test('유튜브 영상 id 모양만 받는다', () {
      expect(isYoutubeVideoId('dQw4w9WgXcQ'), isTrue);
      expect(isYoutubeVideoId('a_b-c1234'), isTrue);
      expect(isYoutubeVideoId(''), isFalse);
      expect(isYoutubeVideoId("x');alert(1);//"), isFalse);
      expect(isYoutubeVideoId('abc'), isFalse);
    });

    test('플레이어 메시지에서 오류 번호를 읽는다', () {
      expect(embedErrorOf('error:150'), '150');
      expect(embedErrorOf('error:101'), '101');
      expect(embedErrorOf('ready'), isNull);
    });
  });

  group('상세 화면의 앱 안 재생', () {
    late FakeLinkOpener opener;
    VoidCallback? fail;

    Future<void> open(
      WidgetTester tester, {
      bool inApp = true,
      MediaHit hit = _yt,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      opener = FakeLinkOpener();
      await setUpTestDependencies(
        engine: FakeDownloaderEngine(info: VideoInfo(hit)),
        linkOpener: opener,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaDetailScreen(
            hit: hit,
            inAppVideo: inApp,
            playerBuilder: (id, onFailed) {
              fail = onFailed;
              return SizedBox(
                key: ValueKey('fake-player-$id'),
                height: 100,
                child: const Text('PLAYER'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('재생 버튼을 누르면 그 자리에서 앱 안 플레이어가 뜬다', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Play in app'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('fake-player-dQw4w9WgXcQ')), findsOne);
      expect(opener.opened, isEmpty); // 유튜브로 나가지 않는다
    });

    testWidgets('임베드가 막히면 앱 안 재생을 접고 유튜브로만 열게 안내한다', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Play in app'));
      await tester.pumpAndSettle();

      fail!(); // 임베드 금지(오류 150 등)
      await tester.pumpAndSettle();

      expect(find.text('PLAYER'), findsNothing);
      expect(
        find.byKey(const ValueKey('detail-embed-blocked')),
        findsOneWidget,
      );
      expect(find.byTooltip('Play in app'), findsNothing);

      // 이제 재생 버튼도 유튜브로 연다.
      await tester.tap(find.byTooltip('Watch on YouTube').first);
      await tester.pumpAndSettle();
      expect(opener.opened, [_yt.url]);
    });

    testWidgets('유튜브로 보기 버튼은 앱 안 재생과 별개로 늘 유튜브로 연다', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('detail-watch')));
      await tester.pumpAndSettle();
      expect(opener.opened, [_yt.url]);
      expect(find.text('PLAYER'), findsNothing);
    });

    testWidgets('앱 안 재생을 못 하는 플랫폼이면 재생 버튼이 유튜브로 연다', (tester) async {
      await open(tester, inApp: false);
      await tester.tap(find.byTooltip('Watch on YouTube').first);
      await tester.pumpAndSettle();
      expect(opener.opened, [_yt.url]);
      expect(find.text('PLAYER'), findsNothing);
    });

    testWidgets('유튜브가 아닌 곳의 곡은 앱 안에서 틀지 않는다', (tester) async {
      const web = MediaHit(
        id: 'abcdef12',
        title: 'Song',
        url: 'https://soundcloud.com/a/b',
        uploader: 'Chan',
      );
      await open(tester, hit: web);
      expect(find.byTooltip('Play in app'), findsNothing);
      await tester.tap(find.byTooltip('Watch on YouTube').first);
      await tester.pumpAndSettle();
      expect(opener.opened, [web.url]);
    });
  });
}
