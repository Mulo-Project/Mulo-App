import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/engine/data/native_yt_dlp.dart';
import 'package:music_download_play_app/features/search/data/engine/routing_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/server_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/yt_dlp_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/search_source.dart';
import 'package:music_download_play_app/features/search/domain/entities/subtitle_track.dart';

/// 네이티브 yt-dlp 엔진(`YtDlpEngine` Kotlin)은 채널로만 만난다. 인자 · JSON 해석은 Kotlin 테스트
/// (`YtDlpParsersTest` · `YtDlpEngineTest`)에 있고, 여기서는 Dart가 값을 바르게 보내고 담는지만 본다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('music_app/ytdlp_engine');
  final calls = <MethodCall>[];

  void mock(Future<Object?> Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) {
            calls.add(call);
            return handler(call);
          });

  YtDlpEngine engine() => YtDlpEngine(NativeYtDlp(channel: channel));

  setUp(calls.clear);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Matcher failure(EngineFailure f) =>
      isA<EngineException>().having((e) => e.failure, 'failure', f);

  group('검색', () {
    test('검색 키를 사이트 · 최신순에 따라 골라 보내고 쪽을 담는다', () async {
      mock(
        (call) async => {
          'items': [
            {'id': 'c', 'title': 'Tc', 'url': 'https://u/c', 'seconds': 100},
          ],
          'hasNext': false,
        },
      );
      final page = await engine().search('노래', page: 1, size: 2);
      expect(calls.single.arguments, {
        'prefix': 'ytsearch',
        'query': '노래',
        'page': 1,
        'size': 2,
      });
      expect(page.items.single.id, 'c');
      expect(page.items.single.duration, const Duration(seconds: 100));
      expect(page.hasNext, isFalse);

      await engine().search('노래', source: SearchSource.soundcloud);
      expect(calls.last.arguments['prefix'], 'scsearch');
      await engine().search('노래', newest: true);
      expect(calls.last.arguments['prefix'], 'ytsearchdate');
      await engine().search(
        '노래',
        source: SearchSource.soundcloud,
        newest: true,
      );
      expect(calls.last.arguments['prefix'], 'scsearch'); // 날짜 순 검색이 없는 사이트
    });

    test('곡 항목의 칸을 모델에 담는다', () async {
      mock(
        (call) async => {
          'items': [
            {
              'id': 'v',
              'title': 'T',
              'url': 'https://w',
              'uploader': 'U',
              'categories': ['Music'],
              'channelUrl': 'https://c',
              'views': 12,
              'uploadDate': '2024-01-31',
              'description': 'd',
              'likes': 5,
              'subscribers': 9,
              'creators': ['A'],
              'subtitleLangs': ['ko', 'en-orig'],
              'autoSubtitleLangs': ['en-orig'],
              'album': 'Al',
              'isLive': true,
            },
          ],
          'hasNext': true,
        },
      );
      final h = (await engine().search('q')).items.single;
      expect(h.uploader, 'U');
      expect(h.categories, ['Music']);
      expect(h.channelUrl, 'https://c');
      expect(h.viewCount, 12);
      expect(h.uploadedAt, DateTime(2024, 1, 31));
      expect(h.likeCount, 5);
      expect(h.subscriberCount, 9);
      expect(h.creators, ['A']);
      expect(h.subtitleLangs, ['ko', 'en-orig']);
      expect(h.autoSubtitleLangs, ['en-orig']);
      expect(h.album, 'Al');
      expect(h.isLive, isTrue);
      expect(h.duration, isNull);
    });

    test('재생목록 검색: 이름 · 채널 · 곡 수', () async {
      mock(
        (call) async => {
          'items': [
            {
              'id': 'PL1',
              'title': 'L',
              'url': 'https://www.youtube.com/playlist?list=PL1',
              'channel': 'C',
              'trackCount': 7,
            },
          ],
          'hasNext': false,
        },
      );
      final page = await engine().searchPlaylists('q');
      expect(calls.single.method, 'searchPlaylists');
      final p = page.items.single;
      expect((p.id, p.title, p.channel, p.trackCount), ('PL1', 'L', 'C', 7));
    });
  });

  group('정보', () {
    test('곡 하나 · 재생목록 · 채널', () async {
      mock((call) async {
        switch (call.method) {
          case 'channel':
            return {'thumbnail': 'https://a', 'subscriberCount': 1234};
          default:
            return call.arguments['url'] == 'list'
                ? {
                    'type': 'playlist',
                    'title': 'L',
                    'entries': [
                      {'id': 'a', 'title': 'Ta', 'url': 'https://u/a'},
                    ],
                    'thumbnail': 'https://t',
                  }
                : {
                    'type': 'video',
                    'hit': {'id': 'v', 'title': 'T', 'url': 'https://u/v'},
                  };
        }
      });
      final video = await engine().fetchInfo('v');
      expect((video as VideoInfo).hit.title, 'T');
      final list = await engine().fetchFullInfo('list');
      expect((list as PlaylistInfo).entries.single.title, 'Ta');
      expect(list.thumbnailUrl, 'https://t');
      final c = await engine().fetchChannel('https://c');
      expect((c.thumbnailUrl, c.subscriberCount), ('https://a', 1234));
    });
  });

  group('재생 주소', () {
    test('소리: 언어를 보내고 주소 · 헤더를 담는다', () async {
      mock(
        (call) async => {
          'url': 'https://a',
          'headers': {'User-Agent': 'x'},
        },
      );
      final a = await engine().resolveAudioStream('u', audioLanguage: 'ko');
      expect(calls.single.arguments, {'url': 'u', 'language': 'ko'});
      expect(a.url, 'https://a');
      expect(a.headers, {'User-Agent': 'x'});
    });

    test('영상: 화질 상한을 보내고 소리 든 형식이면 muxed', () async {
      mock((call) async => {'url': 'https://v', 'headers': {}, 'muxed': true});
      final v = await engine().resolveVideoStream('u', maxHeight: 720);
      expect(calls.single.arguments, {'url': 'u', 'maxHeight': 720});
      expect(v.muxed, isTrue);
    });

    test('오디오 언어 목록', () async {
      mock(
        (call) async => [
          {'id': 'en', 'name': 'English', 'isDefault': true},
          {'id': 'ko', 'name': 'Korean', 'isDefault': false},
        ],
      );
      final l = await engine().fetchAudioLanguages('u');
      expect(l.map((e) => (e.id, e.name, e.isDefault)), [
        ('en', 'English', true),
        ('ko', 'Korean', false),
      ]);
    });
  });

  group('자막', () {
    test('선호 언어를 보내고 받은 줄을 모델에 담는다', () async {
      mock(
        (call) async => {
          'language': 'en',
          'automatic': false,
          'cues': [
            {'ms': 1000, 'text': '첫 줄'},
            {'ms': 65500, 'text': '& 셋째'},
          ],
        },
      );
      final t = await engine().fetchSubtitles('u');
      expect(calls.single.arguments['prefer'], ['ko', 'en']);
      expect(t?.language, 'en');
      expect(t?.cues, [
        const SubtitleCue(Duration(seconds: 1), '첫 줄'),
        const SubtitleCue(Duration(milliseconds: 65500), '& 셋째'),
      ]);
    });

    test('쓸 자막이 없으면 null', () async {
      mock((call) async => null);
      expect(await engine().fetchSubtitles('u'), isNull);
    });
  });

  group('오류와 사용 가능 여부', () {
    test('네이티브 오류 코드를 EngineFailure로 바꾼다', () async {
      for (final (code, f) in [
        ('unavailable', EngineFailure.unavailable),
        ('network', EngineFailure.network),
        ('timeout', EngineFailure.timeout),
        ('not_found', EngineFailure.notFound),
        ('failed', EngineFailure.failed),
        ('other', EngineFailure.failed),
      ]) {
        mock((call) async => throw PlatformException(code: code));
        await expectLater(engine().search('q'), throwsA(failure(f)));
      }
    });

    test('채널이 없는 빌드(lite · Android 밖)는 사용 불가', () async {
      // 처리기가 없으면 MissingPluginException.
      expect(await engine().isAvailable(), isFalse);
      await expectLater(
        engine().search('q'),
        throwsA(failure(EngineFailure.unavailable)),
      );
    });

    test('Routing: 로컬 yt-dlp가 있으면 로컬, 없으면 서버, 둘 다 없으면 unavailable', () async {
      var serverCalls = 0;
      final server = ServerEngine(
        baseUrl: 'https://s',
        get: (_, _) async {
          serverCalls++;
          return (status: 200, body: '{"items":[],"hasNext":false}');
        },
      );
      // 로컬 엔진이 없는 빌드(처리기 없음) → 서버
      await RoutingDownloaderEngine(local: engine(), server: server).search('q');
      expect(serverCalls, 1);
    });
  });

  group('영상 저장', () {
    test('주소 · 화질 · 확장자 · 위치를 한 번에 보내고 진행률을 받는다', () async {
      mock((call) async {
        final id = call.arguments['id'] as String;
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channel.name,
              channel.codec.encodeMethodCall(
                MethodCall('progress', {'id': id, 'progress': 0.5}),
              ),
              (_) {},
            );
        return null;
      });
      final seen = <double>[];
      await NativeYtDlp(channel: channel).saveVideo(
        url: 'u',
        maxHeight: 720,
        extension: 'webm',
        dir: '/tmp/d',
        stem: 'video_1',
        onProgress: seen.add,
      );
      final a = calls.single.arguments as Map;
      expect(a['url'], 'u');
      expect(a['maxHeight'], 720);
      expect(a['extension'], 'webm');
      expect(a['dir'], '/tmp/d');
      expect(a['stem'], 'video_1');
      expect(seen, [0.5]);
    });

    test('못 받으면 EngineException', () async {
      mock((call) async => throw PlatformException(code: 'failed'));
      await expectLater(
        NativeYtDlp(channel: channel).saveVideo(
          url: 'u',
          maxHeight: 720,
          extension: 'mp4',
          dir: '/tmp/d',
          stem: 's',
        ),
        throwsA(failure(EngineFailure.failed)),
      );
    });
  });
}
