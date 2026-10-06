import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_key.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/audio_file_downloader.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/downloaded_file_store.dart';
import 'package:music_download_play_app/features/downloads/data/repositories/engine_download_queue_repository.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_stream.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';

import '../../helpers/fakes.dart';

class _FakeDownloader implements AudioFileDownloader {
  _FakeDownloader({this.failures = 0});

  int failures;
  Completer<void>? gate;
  final urls = <String>[];

  @override
  Future<DownloadedAudio> download(
    AudioStream stream,
    File target, {
    required DownloadCancelToken token,
    required void Function(double progress) onProgress,
  }) async {
    urls.add(stream.url);
    onProgress(.5);
    await gate?.future;
    if (token.isCancelled) throw const DownloadAborted();
    if (failures > 0) {
      failures--;
      throw const DownloadFailed('HTTP 403');
    }
    await target.writeAsBytes([1, 2, 3]);
    onProgress(1);
    return DownloadedAudio(target, 'weba', 'audio/webm');
  }
}

class _FakeStore implements DownloadedFileStore {
  final saved = <({String folder, String name, String ext})>[];

  @override
  Future<SavedAudio> save(
    File source, {
    required String folder,
    required String name,
    required String extension,
    required String mime,
    required String title,
    required String artist,
  }) async {
    saved.add((folder: folder, name: name, ext: extension));
    return SavedAudio(uri: 'content://media/$name.$extension', folder: folder);
  }
}

void main() {
  late Directory tmp;
  late FakeLibraryRepository library;
  late MemoryPlaylistRepository playlists;
  late MemoryCoverRepository covers;
  late MemoryCoverColorRepository colors;
  late _FakeStore store;
  late FakeDownloaderEngine engine;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mulo_dl_test');
    library = FakeLibraryRepository();
    playlists = MemoryPlaylistRepository();
    covers = MemoryCoverRepository();
    colors = MemoryCoverColorRepository();
    store = _FakeStore();
    engine = FakeDownloaderEngine();
  });

  tearDown(() => tmp.delete(recursive: true));

  EngineDownloadQueueRepository build(_FakeDownloader dl) =>
      EngineDownloadQueueRepository(
        engine: engine,
        downloader: dl,
        store: store,
        library: library,
        playlists: playlists,
        covers: covers,
        colors: colors,
        settings: MemoryDownloadSettings(path: '/music/Mulo'),
        tempDir: () async => tmp,
      );

  Future<List<DownloadItem>> settled(
    EngineDownloadQueueRepository repo,
    bool Function(List<DownloadItem>) done,
  ) => repo.watchQueue().firstWhere(done);

  const request = DownloadRequest(
    title: 'Song',
    artist: 'Me',
    genre: 'Pop',
    url: 'https://youtu.be/abc',
    thumbnailUrl: 'https://i.test/a.jpg',
    color: 0xFF112233,
    playlistIds: {'pl1'},
    duration: Duration(minutes: 3),
  );

  test('받기가 끝나면 곡이 보관함에 생기고 커버 · 색 · 재생목록이 붙는다', () async {
    final repo = build(_FakeDownloader());
    await repo.enqueue(request);
    final items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    expect(items.single.progress, 1);
    expect(engine.streams, ['https://youtu.be/abc']);

    final track = (await library.watchTracks().first).single;
    expect(track.title, 'Song');
    expect(track.artist, 'Me');
    expect(track.genre, 'Pop');
    expect(track.source, TrackSource.download);
    expect(track.uri, 'content://media/Me - Song.weba');
    expect(track.folder, '/music/Mulo');
    expect(track.duration, const Duration(minutes: 3));

    expect(covers.saved[CoverKey.track(track.id)]?.url, 'https://i.test/a.jpg');
    expect(colors.saved[CoverKey.track(track.id)], 0xFF112233);
    expect(playlists.members['pl1'], {track.id});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(tmp.listSync(), isEmpty, reason: '임시 파일은 지운다');
  });

  test('실패하면 안내가 남고, 다시 받기로 이어서 성공한다', () async {
    final dl = _FakeDownloader(failures: 1);
    final repo = build(dl);
    await repo.enqueue(request);
    var items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.failed,
    );
    expect(items.single.error, 'HTTP 403');
    expect(await library.watchTracks().first, isEmpty);

    await repo.retry(items.single.id);
    items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    expect(dl.urls, hasLength(2));
    expect(items.single.error, isEmpty);
    expect(await library.watchTracks().first, hasLength(1));
  });

  test('엔진이 주소를 못 읽으면 실패 처리한다', () async {
    engine = FakeDownloaderEngine(streamFailure: EngineFailure.notFound);
    final repo = build(_FakeDownloader());
    await repo.enqueue(request);
    final items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.failed,
    );
    expect(items.single.error, isNotEmpty);
  });

  test('받는 중 취소하면 목록에서 빠지고 곡이 생기지 않는다', () async {
    final dl = _FakeDownloader()..gate = Completer<void>();
    final repo = build(dl);
    await repo.enqueue(request);
    final items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.downloading,
    );
    await repo.cancel(items.single.id);
    dl.gate!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await repo.watchQueue().first, isEmpty);
    expect(await library.watchTracks().first, isEmpty);
    expect(store.saved, isEmpty);
  });

  test('여러 곡은 한 곡씩 차례로 받는다', () async {
    final dl = _FakeDownloader();
    final repo = build(dl);
    await repo.enqueue(request);
    await repo.enqueue(
      const DownloadRequest(title: 'Two', url: 'https://youtu.be/def'),
    );
    await settled(
      repo,
      (l) => l.length == 2 && l.every((e) => e.status == DownloadStatus.done),
    );
    expect(engine.streams, ['https://youtu.be/abc', 'https://youtu.be/def']);
    expect(await library.watchTracks().first, hasLength(2));
  });
}
