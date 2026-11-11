import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/native_tags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('music_app/tags');
  final calls = <MethodCall>[];

  void reply(Object? Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('write: 형식을 모르는 값 · 커버 경로 · 변형만 한 번에 넘기고 상태를 옮긴다', () async {
    reply((_) => {'status': 'written'});
    final status = await const NativeTags().write(
      'content://a/1',
      values: {'title': '제목', 'lyrics': '가사'},
      cover: (
        path: '/img.jpg',
        transform: const CoverTransform(scale: 2, dx: .1),
      ),
      ask: true,
    );
    expect(status, NativeTagStatus.written);
    expect(calls.single.method, 'write');
    final args = calls.single.arguments as Map;
    expect(args['uri'], 'content://a/1');
    expect(args['values'], {'title': '제목', 'lyrics': '가사'});
    expect((args['cover'] as Map)['path'], '/img.jpg');
    expect((args['cover'] as Map)['scale'], 2.0);
    expect(args['ask'], true);
    expect(args.containsKey('format'), isFalse);
  });

  test('write: 실패 이유를 남기고, 상태는 그대로 옮긴다', () async {
    reply((_) => {'status': 'failed', 'error': 'ffmpeg exit 1'});
    expect(await const NativeTags().write('/a.mp3'), NativeTagStatus.failed);
    expect(NativeTags.lastError, 'ffmpeg exit 1');
    reply((_) => {'status': 'denied'});
    expect(await const NativeTags().write('/a.mp3'), NativeTagStatus.denied);
    reply((_) => {'status': 'unsupported'});
    expect(
      await const NativeTags().write('/a.mp3'),
      NativeTagStatus.unsupported,
    );
  });

  test('read · ensure: 네이티브 답을 그대로 돌려준다', () async {
    reply((c) {
      if (c.method == 'read') {
        return {
          'status': 'ok',
          'tags': {'title': 'T'},
        };
      }
      return {'ok': false};
    });
    final r = await const NativeTags().read('/a.opus');
    expect(r.status, 'ok');
    expect(r.tags, {'title': 'T'});
    expect(await const NativeTags().ensure('content://a/1'), isFalse);
  });
}
