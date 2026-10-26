import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_key.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/audio_file_downloader.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/audio_transcoder.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/download_queue_store.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/downloaded_file_store.dart';
import 'package:music_download_play_app/features/downloads/data/repositories/engine_download_queue_repository.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_options.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_source.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_stream.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/subtitle_track.dart';

import '../../helpers/fakes.dart';

class _FakeDownloader implements AudioFileDownloader {
  _FakeDownloader({this.failures = 0});

  int failures;
  Completer<void>? gate;

  /// 받기를 시작해 [gate]에서 기다리기 시작하면 완료된다 (그 전에 멈추면 받은 것이 없다).
  var entered = Completer<void>();
  final urls = <String>[];

  /// 이어받기로 불린 기록: 그때 임시 파일 길이와 넘겨받은 형식.
  final resumes = <({int length, String? mime})>[];

  @override
  Future<DownloadedAudio> download(
    AudioStream stream,
    File target, {
    required DownloadCancelToken token,
    required void Function(double progress) onProgress,
    String? resumeMime,
    void Function(String mime)? onMime,
  }) async {
    urls.add(stream.url);
    final length = await target.exists() ? await target.length() : 0;
    if (length > 0) resumes.add((length: length, mime: resumeMime));
    onMime?.call('audio/webm');
    onProgress(.5);
    if (!entered.isCompleted) entered.complete();
    await gate?.future;
    if (token.isCancelled) {
      // 멈추면 받은 만큼은 파일에 남는다.
      await target.writeAsBytes([1, 2], mode: FileMode.append);
      throw const DownloadAborted();
    }
    if (failures > 0) {
      failures--;
      throw const DownloadFailed('HTTP 403');
    }
    await target.writeAsBytes(
      length > 0 && resumeMime != null ? [3] : [1, 2, 3],
      mode: length > 0 && resumeMime != null ? FileMode.append : FileMode.write,
    );
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
    if (await source.exists()) await source.delete();
    return SavedAudio(uri: 'content://media/$name.$extension', folder: folder);
  }
}

class _FakeTranscoder implements AudioTranscoder {
  bool works = true;

  final plans = <TranscodePlan>[];

  @override
  Future<bool> isAvailable() async => works;

  @override
  Future<DownloadedAudio?> convert(
    DownloadedAudio source,
    TranscodePlan plan,
    File target,
  ) async {
    plans.add(plan);
    if (!works) return null;
    await target.writeAsBytes([9, 9]);
    return DownloadedAudio(target, plan.extension, plan.mime);
  }

  @override
  Future<void> cancel() async {}
}

class _MemoryQueueStore implements DownloadQueueStore {
  List<StoredDownload> queue = [];
  Map<String, String> sources = {};

  @override
  Future<List<StoredDownload>> loadQueue() async => [...queue];

  @override
  Future<void> saveQueue(List<StoredDownload> items) async =>
      queue = [...items];

  @override
  Future<Map<String, String>> loadSources() async => {...sources};

  @override
  Future<void> saveSources(Map<String, String> value) async =>
      sources = {...value};
}

class _LangEngine extends FakeDownloaderEngine {
  _LangEngine(this.seen);

  final List<List<String>> seen;

  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) {
    seen.add(preferLanguages);
    return super.fetchSubtitles(url, preferLanguages: preferLanguages);
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
  late _FakeTranscoder transcoder;
  late _MemoryQueueStore queueStore;
  late MemoryDownloadSettings settings;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mulo_dl_test');
    library = FakeLibraryRepository();
    playlists = MemoryPlaylistRepository();
    covers = MemoryCoverRepository();
    colors = MemoryCoverColorRepository();
    store = _FakeStore();
    engine = FakeDownloaderEngine();
    transcoder = _FakeTranscoder();
    queueStore = _MemoryQueueStore();
    settings = MemoryDownloadSettings(path: '/music/Mulo');
  });

  tearDown(() => tmp.delete(recursive: true));

  EngineDownloadQueueRepository build(
    _FakeDownloader dl, {
    MemoryLyricsRepository? lyrics,
  }) => EngineDownloadQueueRepository(
    engine: engine,
    downloader: dl,
    store: store,
    library: library,
    playlists: playlists,
    covers: covers,
    colors: colors,
    settings: settings,
    transcoder: transcoder,
    queueStore: queueStore,
    tempDir: () async => tmp,
    lyrics: lyrics,
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

  group('자막 가사로 가져오기', () {
    const withLyrics = DownloadRequest(
      title: 'Song',
      url: 'https://youtu.be/abc',
      importLyrics: true,
    );
    const track = SubtitleTrack(
      language: 'ko',
      cues: [
        SubtitleCue(Duration(seconds: 1), '첫 줄'),
        SubtitleCue(Duration(seconds: 65, milliseconds: 500), '둘째 줄'),
      ],
    );

    test('켜 두면 받은 곡에 싱크 가사가 저장된다', () async {
      engine.subtitles = track;
      final lyrics = MemoryLyricsRepository();
      final repo = build(_FakeDownloader(), lyrics: lyrics);
      await repo.enqueue(withLyrics);
      await settled(
        repo,
        (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
      );
      final saved = lyrics.saved.entries.single;
      expect(saved.key, startsWith('download:'));
      expect(saved.value, '[00:01.00]첫 줄\n[01:05.50]둘째 줄');
      expect(engine.subtitleUrls, ['https://youtu.be/abc']);
    });

    test('효과음 줄 빼기는 기본으로 켜져 있고 끌 수 있다', () async {
      final noisy = SubtitleTrack(
        language: 'ko',
        cues: [
          SubtitleCue(Duration(seconds: 1), '[음악]'),
          SubtitleCue(Duration(seconds: 2), '가사'),
        ],
      );
      for (final skip in [true, false]) {
        engine = FakeDownloaderEngine()..subtitles = noisy;
        final lyrics = MemoryLyricsRepository();
        final repo = build(_FakeDownloader(), lyrics: lyrics);
        await repo.enqueue(
          DownloadRequest(
            title: 'Song$skip',
            url: 'https://youtu.be/s$skip',
            importLyrics: true,
            lyricsSkipSounds: skip,
          ),
        );
        await settled(
          repo,
          (l) =>
              l.isNotEmpty && l.every((e) => e.status == DownloadStatus.done),
        );
        expect(
          lyrics.saved.values.single,
          skip ? '[00:02.00]가사' : '[00:01.00][음악]\n[00:02.00]가사',
        );
      }
    });

    test('받기 전에 고친 가사 글은 자막을 다시 읽지 않고 그대로 저장한다', () async {
      engine.subtitles = track;
      final lyrics = MemoryLyricsRepository();
      final repo = build(_FakeDownloader(), lyrics: lyrics);
      await repo.enqueue(
        const DownloadRequest(
          title: 'Song',
          url: 'https://youtu.be/abc',
          importLyrics: true,
          lyricsText: '[00:01.00]고친 줄',
        ),
      );
      await settled(
        repo,
        (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
      );
      expect(lyrics.saved.values.single, '[00:01.00]고친 줄');
      expect(engine.subtitleUrls, isEmpty);
    });

    test('고른 언어를 엔진에 넘긴다', () async {
      final seen = <List<String>>[];
      engine = _LangEngine(seen)..subtitles = track;
      final repo = build(_FakeDownloader(), lyrics: MemoryLyricsRepository());
      await repo.enqueue(
        const DownloadRequest(
          title: 'Song',
          url: 'https://youtu.be/abc',
          importLyrics: true,
          lyricsLanguage: 'en',
        ),
      );
      await settled(
        repo,
        (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
      );
      expect(seen, [
        ['en'],
      ]);
    });

    test('끄면 자막을 읽지 않는다', () async {
      engine.subtitles = track;
      final lyrics = MemoryLyricsRepository();
      final repo = build(_FakeDownloader(), lyrics: lyrics);
      await repo.enqueue(request);
      await settled(
        repo,
        (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
      );
      expect(engine.subtitleUrls, isEmpty);
      expect(lyrics.saved, isEmpty);
    });

    test('자막이 없어도 받기는 성공이고 가사는 비어 있다', () async {
      final lyrics = MemoryLyricsRepository();
      final repo = build(_FakeDownloader(), lyrics: lyrics);
      await repo.enqueue(withLyrics);
      final items = await settled(
        repo,
        (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
      );
      expect(items.single.error, isEmpty);
      expect(lyrics.saved, isEmpty);
    });
  });

  test('주소가 막히면(403) 기억한 주소를 버리고 새로 읽어 한 번 더 받는다', () async {
    final dl = _FakeDownloader(failures: 1);
    final repo = build(dl);
    await repo.enqueue(request);
    final items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    expect(dl.urls, hasLength(2));
    expect(engine.refreshFlags, [false, true]);
    expect(items.single.error, isEmpty);
  });

  test('실패하면 안내가 남고, 다시 받기로 이어서 성공한다', () async {
    final dl = _FakeDownloader(failures: 2);
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
    expect(dl.urls, hasLength(3));
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

  test('일시정지하면 받은 만큼 남겨 두고, 이어받기는 그 파일 뒤에 이어 받는다', () async {
    final dl = _FakeDownloader()..gate = Completer<void>();
    final repo = build(dl);
    await repo.enqueue(request);
    var items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.downloading,
    );
    final id = items.single.id;
    await dl.entered.future;
    await repo.pause(id);
    dl.gate!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(File('${tmp.path}/$id.part').lengthSync(), 2, reason: '받은 만큼 남김');
    expect(queueStore.queue.single.partMime, 'audio/webm');

    dl.gate = null;
    await repo.resume(id);
    items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    expect(dl.resumes, [(length: 2, mime: 'audio/webm')]);
    expect(await library.watchTracks().first, hasLength(1));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(tmp.listSync(), isEmpty, reason: '다 받으면 임시 파일을 지운다');
  });

  test('대기열을 저장해 두면 앱을 다시 켠 뒤 이어서 받는다', () async {
    final first = _FakeDownloader()..gate = Completer<void>();
    final repo = build(first);
    await repo.enqueue(request);
    await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.downloading,
    );
    expect(queueStore.queue, hasLength(1));
    expect(queueStore.queue.single.request.url, 'https://youtu.be/abc');

    // 앱이 꺼졌다가 새로 켜진 것처럼 같은 저장소로 새 대기열을 만든다.
    final second = _FakeDownloader();
    final restored = build(second);
    final items = await settled(
      restored,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    expect(items.single.title, 'Song');
    expect(second.urls, hasLength(1));
    expect(engine.streams.last, 'https://youtu.be/abc');
    expect(await library.watchTracks().first, hasLength(1));
    expect(queueStore.queue, isEmpty, reason: '끝난 곡은 저장 목록에서 뺀다');
    // 꺼진 것으로 친 첫 대기열의 남은 작업을 정리한다.
    await repo.cancel(items.single.id);
    first.gate!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('일시정지한 곡은 다시 켜도 일시정지로 남는다', () async {
    final dl = _FakeDownloader()..gate = Completer<void>();
    final repo = build(dl);
    await repo.enqueue(request);
    final items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.downloading,
    );
    await repo.pause(items.single.id);
    dl.gate!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final restored = build(_FakeDownloader());
    final after = await restored.watchQueue().first;
    expect(after.single.status, DownloadStatus.paused);
  });

  test('mp3로 정하면 받은 뒤 mp3로 바꿔 저장한다 (항상 최고 음질 192kbps)', () async {
    settings.format = AudioFormat.mp3;
    final repo = build(_FakeDownloader());
    await repo.enqueue(request);
    await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    expect(transcoder.plans.single.bitrateKbps, 192);
    expect(store.saved.single.ext, 'mp3');
    expect(
      (await library.watchTracks().first).single.uri,
      'content://media/Me - Song.mp3',
    );
  });

  test('곡마다 정한 형식이 설정의 기본보다 먼저다', () async {
    settings.format = AudioFormat.mp3;
    final repo = build(_FakeDownloader());
    await repo.enqueue(
      const DownloadRequest(
        title: 'Two',
        url: 'https://youtu.be/def',
        format: AudioFormat.opus,
      ),
    );
    await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    // opus는 받은 원본 그대로 저장한다 (다시 인코딩하지 않는다).
    expect(transcoder.plans, isEmpty);
    expect(store.saved.single.ext, 'weba');
  });

  test('변환기가 없으면 받은 원본 그대로 저장한다', () async {
    settings.format = AudioFormat.mp3;
    transcoder.works = false;
    final repo = build(_FakeDownloader());
    await repo.enqueue(request);
    await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    expect(store.saved.single.ext, 'weba');
  });

  test('기본(opus · 최고)은 변환하지 않는다', () async {
    final repo = build(_FakeDownloader());
    await repo.enqueue(request);
    await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    expect(transcoder.plans, isEmpty);
  });

  test('이미 받은 곡 · 받는 중인 곡을 원본 주소로 찾는다', () async {
    final dl = _FakeDownloader()..gate = Completer<void>();
    final repo = build(dl);
    expect(
      await repo.findExisting('https://youtu.be/abc'),
      ExistingDownload.none,
    );

    await repo.enqueue(request);
    // 같은 영상의 다른 주소 모양도 같은 곡으로 본다.
    final inQueue = await repo.findExisting(
      'https://www.youtube.com/watch?v=abc&list=PL1',
    );
    expect(inQueue.inQueue, isTrue);
    expect(inQueue.trackId, isNull);

    dl.gate!.complete();
    await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    final done = await repo.findExisting('https://youtu.be/abc');
    expect(done.trackId, startsWith('download:'));
    expect(done.inQueue, isFalse);

    // 보관함에서 지운 곡은 받은 곡으로 치지 않는다.
    await library.delete(done.trackId!);
    expect(
      await repo.findExisting('https://youtu.be/abc'),
      ExistingDownload.none,
    );
  });

  test('받은 곡 키는 받으면 생기고, 보관함에서 지우면 사라진다', () async {
    final repo = build(_FakeDownloader());
    final seen = <Set<String>>[];
    final sub = repo.watchDownloadedKeys().listen(seen.add);
    await repo.enqueue(request);
    final items = await settled(
      repo,
      (l) => l.isNotEmpty && l.single.status == DownloadStatus.done,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last, {'youtube:abc'});

    final id = (await library.watchTracks().first).single.id;
    await library.delete(id);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last, isEmpty);
    expect(items.single.status, DownloadStatus.done);
    await sub.cancel();
  });
}
