import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/library/data/repositories/drift_library_repository.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/playlists/data/repositories/drift_playlist_repository.dart';

void main() {
  late AppDatabase db;
  late DriftPlaylistRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftPlaylistRepository(db);
  });
  tearDown(() => db.close());

  test('재생목록을 만들면 만든 순서로 나오고 곡 수는 0', () async {
    await repo.create('운동');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.create('출근길');
    final lists = await repo.watchPlaylists().first;
    expect(lists.map((p) => p.name), ['운동', '출근길']);
    expect(lists.every((p) => p.trackCount == 0), isTrue);
  });

  test('곡을 여러 재생목록에 넣고, 같은 곡을 또 넣어도 한 번만 센다', () async {
    final a = await repo.create('A');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final b = await repo.create('B');
    await repo.addTrack('t1', [a.id, b.id]);
    await repo.addTrack('t1', [a.id]);
    await repo.addTrack('t2', [a.id]);
    final lists = await repo.watchPlaylists().first;
    expect(lists.map((p) => p.trackCount), [2, 1]);
  });

  test('보관함 곡의 장르가 저장된다 (없으면 빈 문자열)', () async {
    final library = DriftLibraryRepository(db);
    await library.addTracks([
      Track(
        id: 'a',
        title: 'A',
        artist: '',
        album: '',
        genre: '발라드',
        duration: const Duration(minutes: 3),
        uri: 'u1',
        addedAt: DateTime(2026, 9, 1),
      ),
      Track(
        id: 'b',
        title: 'B',
        artist: '',
        album: '',
        duration: const Duration(minutes: 3),
        uri: 'u2',
        addedAt: DateTime(2026, 9, 2),
      ),
    ]);
    final list = await library.watchTracks().first;
    expect(list.map((t) => t.genre), ['', '발라드']);
  });
}
