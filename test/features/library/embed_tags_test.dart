import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/usecase/usecase.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_key.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/entities/track_info.dart';
import 'package:music_download_play_app/features/library/domain/repositories/track_tag_repository.dart';
import 'package:music_download_play_app/features/library/domain/usecases/library_usecases.dart';

import '../../helpers/fakes.dart';

Track _track(String id, TrackSource source) => Track(
  id: id,
  title: 'T$id',
  artist: 'A',
  album: '',
  duration: Duration.zero,
  uri: 'content://$id',
  addedAt: DateTime(2026, 10, 22),
  source: source,
);

class _Tags implements TrackTagRepository {
  @override
  String? get lastFailure => null;

  @override
  Future<bool> ensureWriteAccess(Track track) async => true;

  @override
  Future<bool> ensureWriteAccessAll(List<Track> tracks) async => true;

  final written = <String>[];
  String? lastTitle;
  CoverArt? lastCover;
  bool? lastInteractive;
  TagWriteResult result = TagWriteResult.written;

  @override
  Future<TagWriteResult> write(
    Track track, {
    CoverArt? cover,
    int? color,
    bool interactive = false,
  }) async {
    written.add(track.id);
    lastTitle = track.title;
    lastCover = cover;
    lastInteractive = interactive;
    return result;
  }

  @override
  Future<TagWriteResult> writeLyrics(Track track, String lyrics) async =>
      result;
}

class _Done implements TagMigrationStore {
  final done = <String>{};

  @override
  Future<Set<String>> loadDone() async => {...done};

  @override
  Future<void> markDone(Iterable<String> trackIds) async =>
      done.addAll(trackIds);
}

void main() {
  test('EmbedTagsIntoFiles: 받은 곡만 한 번씩 쓰고, 못 써도 다시 시도하지 않는다', () async {
    final library = FakeLibraryRepository([
      _track('d1', TrackSource.download),
      _track('d2', TrackSource.download),
      _track('x1', TrackSource.device),
    ]);
    final tags = _Tags();
    final done = _Done();
    final useCase = EmbedTagsIntoFiles(
      library,
      MemoryCoverRepository(),
      MemoryCoverColorRepository(),
      tags,
      done,
    );

    expect(await useCase(const NoParams()), 2);
    expect(tags.written.toSet(), {'d1', 'd2'});
    expect(done.done, {'d1', 'd2'});

    tags.written.clear();
    expect(await useCase(const NoParams()), 0);
    expect(tags.written, isEmpty);
  });

  test('EmbedTagsIntoFiles: 쓰기가 false여도 이관은 끝낸 것으로 기록한다', () async {
    final tags = _Tags()..result = TagWriteResult.failed;
    final done = _Done();
    final useCase = EmbedTagsIntoFiles(
      FakeLibraryRepository([_track('d1', TrackSource.download)]),
      MemoryCoverRepository(),
      MemoryCoverColorRepository(),
      tags,
      done,
    );
    expect(await useCase(const NoParams()), 0);
    expect(done.done, {'d1'});
  });

  group('EmbedTrackCover: 고른 커버를 곡 파일 태그에 쓴다', () {
    test('웹 커버와 확대 · 위치를 그대로 넘기고, 사용자가 한 저장이라 동의 창을 허용한다', () async {
      final covers = MemoryCoverRepository();
      const transform = CoverTransform(scale: 1.5, dx: .1);
      await covers.saveUrl(
        CoverKey.track('d1'),
        'https://example.com/a.jpg',
        transform: transform,
      );
      final tags = _Tags();
      final useCase = EmbedTrackCover(
        FakeLibraryRepository([_track('d1', TrackSource.download)]),
        covers,
        MemoryCoverColorRepository(),
        tags,
      );

      expect(await useCase('d1'), TagWriteResult.written);
      expect(tags.written, ['d1']);
      expect(
        tags.lastCover,
        const CoverArt.web('https://example.com/a.jpg', transform: transform),
      );
      expect(tags.lastInteractive, isTrue);
    });

    test('커버가 없으면 쓰지 않는다', () async {
      final tags = _Tags();
      final useCase = EmbedTrackCover(
        FakeLibraryRepository([_track('d1', TrackSource.download)]),
        MemoryCoverRepository(),
        MemoryCoverColorRepository(),
        tags,
      );
      expect(await useCase('d1'), TagWriteResult.unsupported);
      expect(tags.written, isEmpty);
    });
  });

  group('UpdateTrackInfo: 태그를 먼저 쓰고 DB에 저장', () {
    const params = UpdateTrackInfoParams('d1', TrackInfo(title: '새 제목'));

    Future<(FakeLibraryRepository, _Tags)> setUp(
      TrackSource source,
      TagWriteResult result,
    ) async {
      final library = FakeLibraryRepository([_track('d1', source)]);
      return (library, _Tags()..result = result);
    }

    Future<String> titleOf(FakeLibraryRepository l) async =>
        (await l.watchTracks().first).single.title;

    test('쓰기 성공이면 새 값을 태그에 쓰고 DB도 고친다', () async {
      final (library, tags) = await setUp(
        TrackSource.download,
        TagWriteResult.written,
      );
      expect(
        await UpdateTrackInfo(library, tags)(params),
        UpdateInfoResult.saved,
      );
      expect(tags.lastTitle, '새 제목');
      expect(await titleOf(library), '새 제목');
    });

    test('쓰기가 실패하면 DB를 바꾸지 않는다', () async {
      final (library, tags) = await setUp(
        TrackSource.download,
        TagWriteResult.failed,
      );
      expect(
        await UpdateTrackInfo(library, tags)(params),
        UpdateInfoResult.tagWriteFailed,
      );
      expect(await titleOf(library), 'Td1');
    });

    test('태그를 쓰지 않는 곡은 DB만 고친다', () async {
      final (library, tags) = await setUp(
        TrackSource.download,
        TagWriteResult.unsupported,
      );
      expect(
        await UpdateTrackInfo(library, tags)(params),
        UpdateInfoResult.saved,
      );
      expect(await titleOf(library), '새 제목');
    });

    test('기기 곡의 쓰기 권한 없음은 DB만 고치고, 받은 곡은 실패로 본다', () async {
      final (device, deviceTags) = await setUp(
        TrackSource.device,
        TagWriteResult.denied,
      );
      expect(
        await UpdateTrackInfo(device, deviceTags)(params),
        UpdateInfoResult.saved,
      );
      final (dl, dlTags) = await setUp(
        TrackSource.download,
        TagWriteResult.denied,
      );
      expect(
        await UpdateTrackInfo(dl, dlTags)(params),
        UpdateInfoResult.tagWriteFailed,
      );
      expect(await titleOf(dl), 'Td1');
    });

    test('제목이 비면 태그도 DB도 건드리지 않는다', () async {
      final (library, tags) = await setUp(
        TrackSource.download,
        TagWriteResult.written,
      );
      expect(
        await UpdateTrackInfo(library, tags)(
          const UpdateTrackInfoParams('d1', TrackInfo(title: '  ')),
        ),
        UpdateInfoResult.invalid,
      );
      expect(tags.written, isEmpty);
    });
  });
}
