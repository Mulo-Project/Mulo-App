import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_download_play_app/features/downloads/data/repositories/native_download_queue_repository.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_options.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';

import '../../helpers/fakes.dart';

/// 받기 큐는 네이티브(`music_app/downloads`)가 한다: 요청을 그대로 넘기고, 네이티브가 알리는 상태를 그린다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('music_app/downloads');
  late MemoryDownloadSettings settings;
  late List<MethodCall> calls;
  late List<Map<String, Object?>> snapshot;
  var opened = 0;
  var libraryChanged = 0;
  final errors = <String>[];

  NativeDownloadQueueRepository make() => NativeDownloadQueueRepository(
    settings: settings,
    openLibrary: () async => opened++,
    onEngineError: errors.add,
    onLibraryChanged: () => libraryChanged++,
    channel: channel,
  );

  /// 네이티브가 Dart로 보내는 호출을 흉내 낸다.
  Future<void> fromNative(String method, Object? args) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, args),
          ),
          (_) {},
        );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = MemoryDownloadSettings();
    calls = [];
    snapshot = [];
    opened = 0;
    libraryChanged = 0;
    errors.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'snapshot':
              return snapshot;
            case 'enqueue':
              return 'd1';
            case 'cancelAll':
              return 2;
            case 'findExisting':
              return {'trackId': 'download:d0', 'inQueue': true};
            case 'sourceUrlOf':
              return 'https://youtu.be/x';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('처음 쓸 때 보관함 DB를 열고 네이티브에 알리며 지금 대기열을 받아 온다', () async {
    snapshot = [
      {
        'id': 'd1',
        'title': '곡',
        'artist': '가수',
        'status': 'downloading',
        'progress': 0.5,
        'playlistIds': ['p1'],
        'url': 'https://youtu.be/x',
      },
    ];
    final items = await make().watchQueue().first;
    expect(opened, 1);
    expect(calls.map((c) => c.method), containsAllInOrder(['dbReady', 'snapshot']));
    expect(items.single.status, DownloadStatus.downloading);
    expect(items.single.progress, 0.5);
    expect(items.single.playlistIds, {'p1'});
  });

  test('네이티브가 알리는 대기열 변화를 그대로 흘려보낸다', () async {
    final repo = make();
    final seen = <List<DownloadItem>>[];
    final sub = repo.watchQueue().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    await fromNative('queue', [
      {'id': 'd1', 'title': '곡', 'artist': '', 'status': 'failed', 'error': '끊김'},
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last.single.status, DownloadStatus.failed);
    expect(seen.last.single.error, '끊김');
    await sub.cancel();
  });

  test('받기를 넣을 때 형식과 저장 폴더를 정해 null 없이 넘긴다', () async {
    settings.path = '/music/Mulo';
    await make().enqueue(const DownloadRequest(title: '곡', url: 'https://youtu.be/x'));
    final call = calls.firstWhere((c) => c.method == 'enqueue');
    final request = jsonDecode((call.arguments as Map)['request'] as String) as Map;
    expect(request['title'], '곡');
    expect(request['resolvedFolder'], '/music/Mulo');
    expect(request['resolvedFormat'], isNotNull);
    expect(request.containsValue(null), isFalse);
    expect(request.containsKey('thumbnailUrl'), isFalse);
  });

  test('영상으로 저장하면 영상 폴더를 정한다', () async {
    await make().enqueue(
      const DownloadRequest(
        title: '곡',
        url: 'https://youtu.be/x',
        videoFormat: VideoFormat.mp4,
      ),
    );
    final call = calls.firstWhere((c) => c.method == 'enqueue');
    final request = jsonDecode((call.arguments as Map)['request'] as String) as Map;
    expect(request['videoFormat'], 'mp4');
    expect(request['resolvedFolder'], contains('Movies'));
  });

  test('일시정지 · 이어받기 · 다시 시도 · 취소는 항목 id만 네이티브에 넘긴다', () async {
    final repo = make();
    await repo.pause('a');
    await repo.resume('b');
    await repo.retry('c');
    await repo.cancel('d');
    expect(await repo.cancelAll(playlistId: 'p'), 2);
    final sent = {
      for (final c in calls.where((c) => const {'pause', 'resume', 'retry', 'cancel'}.contains(c.method)))
        c.method: (c.arguments as Map)['id'],
    };
    expect(sent, {'pause': 'a', 'resume': 'b', 'retry': 'c', 'cancel': 'd'});
  });

  test('이미 받은 곡 찾기와 원본 주소는 네이티브 기록에 묻는다', () async {
    final repo = make();
    final existing = await repo.findExisting('https://youtu.be/x');
    expect(existing.trackId, 'download:d0');
    expect(existing.inQueue, isTrue);
    expect(await repo.sourceUrlOf('download:d0'), 'https://youtu.be/x');
  });

  test('태그 결과 · 마지막 저장 폴더 · 엔진 오류 · 보관함 변경을 받는다', () async {
    final repo = make();
    await repo.watchQueue().first;
    final notices = <String>[];
    final sub = repo.watchTagNotices().listen((n) => notices.add('${n.title}:${n.ok}'));
    await fromNative('tagNotice', {'title': '곡', 'extension': 'opus', 'ok': false, 'detail': 'x'});
    await fromNative('saved', '/music/Mulo');
    await fromNative('engineError', 'Unable to extract');
    await fromNative('libraryChanged', null);
    await Future<void>.delayed(Duration.zero);
    expect(notices, ['곡:false']);
    expect(settings.last, '/music/Mulo');
    expect(errors, ['Unable to extract']);
    expect(libraryChanged, 1);
    await sub.cancel();
  });
}
