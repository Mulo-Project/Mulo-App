import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/account/data/datasources/google_auth_source.dart';
import 'package:music_download_play_app/features/account/data/datasources/native_google_api.dart';
import 'package:music_download_play_app/features/account/data/repositories/google_account_repository.dart';
import 'package:music_download_play_app/features/account/domain/entities/google_account.dart';

class _Auth implements GoogleAuthSource {
  @override
  Future<String> accessToken() async => 't';
  @override
  Future<GoogleAccount?> restore() async => null;
  @override
  Future<GoogleAccount> signIn() =>
      Future.value(const GoogleAccount(id: 'u', email: 'a@b.c'));
  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/google_api');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  GoogleAccountRepository repo() =>
      GoogleAccountRepository(auth: _Auth(), api: NativeGoogleApi(channel: channel));

  test('구독 목록은 네이티브가 읽어 준 항목을 채널로 바꾸고 진행을 전한다', () async {
    Object? sent;
    messenger.setMockMethodCallHandler(channel, (call) async {
      sent = call.arguments;
      final id = (call.arguments as Map)['progressId'];
      // 네이티브가 쪽을 읽을 때마다 진행을 알린다.
      for (final loaded in [50, 100]) {
        await messenger.handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            MethodCall('progress', {'id': id, 'loaded': loaded}),
          ),
          (_) {},
        );
      }
      return [
        for (var i = 0; i < 100; i++)
          {'id': 'UC$i', 'name': 'c$i', 'description': '', 'thumbnail': null},
      ];
    });
    final progress = <int>[];
    final all = await repo().mySubscriptions(onProgress: progress.add);
    expect(all, hasLength(100));
    expect(all.first.id, 'UC0');
    expect(progress, [50, 100]);
    expect((sent as Map)['token'], 't');
    expect((sent as Map)['kind'], 'subscriptions');
  });

  test('내 재생목록 · 채널 재생목록 항목을 재생목록으로 바꾼다', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => [
      {
        'id': 'PL1',
        'title': '운동',
        'url': 'https://www.youtube.com/playlist?list=PL1',
        'channel': '나',
        'thumbnail': 'mid',
        'trackCount': 7,
      },
    ]);
    final hit = (await repo().myPlaylists()).single;
    expect(hit.title, '운동');
    expect(hit.channel, '나');
    expect(hit.trackCount, 7);
    expect(hit.thumbnailUrl, 'mid');
    expect(hit.url, 'https://www.youtube.com/playlist?list=PL1');
  });

  test('네이티브 오류 코드를 계정 오류로 바꾼다', () async {
    for (final (code, failure) in [
      ('unauthorized', AccountFailure.unauthorized),
      ('no_channel', AccountFailure.noChannel),
      ('network', AccountFailure.network),
      ('timeout', AccountFailure.timeout),
      ('failed', AccountFailure.failed),
    ]) {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: code, message: 'm'),
      );
      await expectLater(
        repo().myPlaylists(),
        throwsA(
          isA<AccountException>().having((e) => e.failure, 'failure', failure),
        ),
      );
    }
  });
}
