import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/engine/data/android_yt_dlp.dart';
import 'package:music_download_play_app/features/search/data/engine/local_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('music_app/ytdlp');

  void mock(Future<Object?> Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('revert: 네이티브에 revert를 부르고, 실패하면 예외를 던진다', () async {
    final calls = <String>[];
    mock((call) async {
      calls.add(call.method);
      return null;
    });
    await AndroidYtDlp(channel: channel).revert();
    expect(calls, ['revert']);

    mock((call) async => throw PlatformException(code: 'ytdlp_failed'));
    expect(
      AndroidYtDlp(channel: channel).revert(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('run: 마지막 인자는 url, 나머지는 옵션으로 보낸다', () async {
    MethodCall? seen;
    mock((call) async {
      seen = call;
      return {'exitCode': 0, 'stdout': 'out', 'stderr': ''};
    });
    final r = await AndroidYtDlp(channel: channel)
        .run('yt-dlp', ['--flat-playlist', '--dump-json', 'ytsearch5:노래']);
    expect(seen!.method, 'run');
    expect(seen!.arguments, {
      'url': 'ytsearch5:노래',
      'options': ['--flat-playlist', '--dump-json'],
      'id': seen!.arguments['id'],
      'background': false,
      'progress': false,
    });
    expect(r.stdout, 'out');
  });

  test('--version은 version 호출로 바뀐다', () async {
    mock((call) async => {'version': '2026.01.01'});
    final r = await AndroidYtDlp(channel: channel)
        .run('yt-dlp', const ['--version']);
    expect(r.exitCode, 0);
    expect(r.stdout, '2026.01.01');
  });

  test('구현이 없는 빌드(lite)면 ProcessException → LocalEngine은 사용 불가', () async {
    // 채널 핸들러가 없으면 MissingPluginException.
    final android = AndroidYtDlp(channel: channel);
    await expectLater(
      android.run('yt-dlp', const ['--version']),
      throwsA(isA<ProcessException>()),
    );
    expect(await LocalEngine(run: android.run).isAvailable(), isFalse);
  });

  testWidgets('run: 응답이 없으면 시간 초과를 던지고 네이티브 실행을 끊는다', (tester) async {
    final calls = <String>[];
    mock((call) {
      calls.add(call.method);
      return call.method == 'run'
          ? Completer<Object?>().future
          : Future.value(true);
    });
    Object? error;
    AndroidYtDlp(channel: channel)
        .run('yt-dlp', ['ytsearch1:x'])
        .catchError((Object e) {
          error = e;
          return (exitCode: 0, stdout: '', stderr: '');
        });
    await tester.pump(ytDlpTimeout + const Duration(seconds: 1));
    expect(error, isA<TimeoutException>());
    expect(calls, ['run', 'cancel']);
  });
}
