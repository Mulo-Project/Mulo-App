import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/usecase/usecase.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
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
  final written = <String>[];
  bool works = true;

  @override
  Future<bool> write(Track track, {CoverArt? cover, int? color}) async {
    written.add(track.id);
    return works;
  }
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
    final tags = _Tags()..works = false;
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

  test('UpdateTrackInfo: DB를 고친 뒤 파일 태그에도 쓴다', () async {
    final library = FakeLibraryRepository([_track('d1', TrackSource.download)]);
    final tags = _Tags();
    final ok = await UpdateTrackInfo(library, tags)(
      const UpdateTrackInfoParams('d1', TrackInfo(title: '새 제목')),
    );
    expect(ok, isTrue);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(tags.written, ['d1']);
  });
}
