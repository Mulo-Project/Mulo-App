import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/engine/data/android_yt_dlp.dart';

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

  test('version: 비어 있거나 구현이 없으면 null', () async {
    mock((call) async => {'version': '2026.01.01'});
    expect(await AndroidYtDlp(channel: channel).version(), '2026.01.01');
    mock((call) async => {'version': ''});
    expect(await AndroidYtDlp(channel: channel).version(), isNull);
    mock((call) async => throw PlatformException(code: 'x'));
    expect(await AndroidYtDlp(channel: channel).version(), isNull);
  });
}
