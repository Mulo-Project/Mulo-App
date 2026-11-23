import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/data/datasources/native_youtube_resolver.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('music_app/youtube_resolve');

  void mock(Future<Object?> Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  final resolver = NativeYoutubeResolver(channel: channel);

  test('audio: 주소 · 헤더 · 대체 주소를 받는다', () async {
    MethodCall? seen;
    mock((call) async {
      seen = call;
      return {
        'url': 'https://a/1',
        'headers': {'user-agent': 'ua'},
        'fallbacks': [
          {
            'url': 'https://a/2',
            'headers': {'user-agent': 'ua2'},
          },
        ],
      };
    });
    final s = await resolver.audio('vid', language: 'ko');
    expect(seen!.method, 'audio');
    expect((seen!.arguments as Map)['videoId'], 'vid');
    expect((seen!.arguments as Map)['language'], 'ko');
    expect(s!.url, 'https://a/1');
    expect(s.headers['user-agent'], 'ua');
    expect(s.fallbacks.single.url, 'https://a/2');
  });

  test('audio · video: 읽을 게 없으면 null', () async {
    mock((call) async => null);
    expect(await resolver.audio('vid'), isNull);
    expect(await resolver.video('vid', 360), isNull);
  });

  test('video: muxed 여부를 받는다', () async {
    mock(
      (call) async => {
        'url': 'https://v/1',
        'headers': {'user-agent': 'ua'},
        'muxed': true,
      },
    );
    final v = await resolver.video('vid', 360);
    expect(v!.muxed, isTrue);
    expect(v.url, 'https://v/1');
  });

  test('languages: 목록을 AudioLanguage로 바꾼다', () async {
    mock(
      (call) async => [
        {'id': 'ko', 'name': 'Korean', 'isDefault': true},
        {'id': 'en-US', 'name': 'English', 'isDefault': false},
      ],
    );
    final l = await resolver.languages('vid');
    expect(l.map((e) => e.id), ['ko', 'en-US']);
    expect(l.first.isDefault, isTrue);
  });

  test('네이티브 오류는 EngineException으로 바뀐다', () async {
    mock(
      (call) async =>
          throw PlatformException(code: 'resolve_failed', message: 'HTTP 403'),
    );
    expect(
      resolver.audio('vid'),
      throwsA(
        isA<EngineException>().having((e) => e.message, 'message', 'HTTP 403'),
      ),
    );
  });
}
