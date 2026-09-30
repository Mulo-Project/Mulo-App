import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/library/data/drift_library_repository.dart';
import 'package:music_download_play_app/features/library/domain/track.dart';

Track _t(String id, String uri, int day) => Track(
  id: id,
  title: 'Song $id',
  artist: '',
  album: 'A',
  duration: const Duration(minutes: 3),
  uri: uri,
  addedAt: DateTime(2026, 9, day),
);

void main() {
  late AppDatabase db;
  late DriftLibraryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftLibraryRepository(db);
  });
  tearDown(() => db.close());

  test('addTracks는 새 곡 수를 돌려주고 같은 uri는 건너뛴다', () async {
    expect(await repo.addTracks([_t('a', 'u1', 1), _t('b', 'u2', 2)]), 2);
    expect(await repo.addTracks([_t('c', 'u2', 3), _t('d', 'u3', 4)]), 1);
  });

  test('watchTracks는 추가일 최신순, 필드를 그대로 돌려준다', () async {
    await repo.addTracks([_t('a', 'u1', 1), _t('b', 'u2', 5)]);
    final list = await repo.watchTracks().first;
    expect(list.map((t) => t.id), ['b', 'a']);
    expect(list.first.uri, 'u2');
    expect(list.first.duration, const Duration(minutes: 3));
    expect(list.first.source, TrackSource.device);
  });
}
