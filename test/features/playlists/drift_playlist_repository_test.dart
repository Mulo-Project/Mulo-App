import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/library/data/repositories/drift_library_repository.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/playlists/data/repositories/drift_playlist_repository.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';

void main() {
  late AppDatabase db;
  late DriftPlaylistRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftPlaylistRepository(db);
  });
  tearDown(() => db.close());

  /// 좋아요 목록(항상 맨 앞)을 뺀, 직접 만든 재생목록.
  Future<List<Playlist>> userLists() async =>
      (await repo.watchPlaylists().first).where((p) => !p.isFavorites).toList();

  test('재생목록을 만들면 만든 순서로 나오고 곡 수는 0', () async {
    await repo.create('운동');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.create('출근길');
    final lists = await userLists();
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
    final lists = await userLists();
    expect(lists.map((p) => p.trackCount), [2, 1]);
  });

  test('removeTrack은 그 재생목록에서만 곡을 뺀다', () async {
    final a = await repo.create('A');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final b = await repo.create('B');
    await repo.addTrack('t1', [a.id, b.id]);
    await repo.addTrack('t2', [a.id]);

    await repo.removeTrack('t1', a.id);

    final lists = await userLists();
    expect(lists.map((p) => p.trackCount), [1, 1]);
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

  group('카드 요약 · 색', () {
    Track track(String id, String title, String artist) => Track(
      id: id,
      title: title,
      artist: artist,
      album: '',
      duration: const Duration(minutes: 3),
      uri: 'u-$id',
      addedAt: DateTime(2026, 9, 1),
    );

    Future<void> play(String trackId, int times) async {
      for (var i = 0; i < times; i++) {
        await db
            .into(db.plays)
            .insert(
              PlaysCompanion.insert(
                trackId: trackId,
                playedAt: DateTime(2026, 9, 2, i),
              ),
            );
      }
    }

    test('대표곡은 가장 많이 들은 곡 (횟수가 같으면 먼저 담은 곡)', () async {
      await DriftLibraryRepository(db).addTracks([
        track('a', 'A곡', '가수1'),
        track('b', 'B곡', '가수1'),
        track('c', 'C곡', '가수2'),
      ]);
      final pl = await repo.create('모음');
      await repo.addTracks(['a', 'b', 'c'], pl.id);
      await play('b', 5);
      await play('a', 2);
      await play('zzz', 9); // 이 재생목록에 없는 곡은 세지 않는다.

      final got = (await userLists()).single;
      expect(got.featured?.id, 'b');
      expect(got.featured?.title, 'B곡');
    });

    test('들은 기록이 없으면 가장 먼저 담은 곡, 곡이 없으면 대표곡도 없다', () async {
      await DriftLibraryRepository(db)
          .addTracks([track('a', 'A', '가수1'), track('b', 'B', '가수2')]);
      final pl = await repo.create('모음');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final empty = await repo.create('빈 목록');
      await repo.addTrack('b', [pl.id]);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.addTrack('a', [pl.id]);

      final lists = await userLists();
      expect(lists.firstWhere((p) => p.id == pl.id).featured?.id, 'b');
      expect(lists.firstWhere((p) => p.id == pl.id).trackCount, 2);
      expect(lists.firstWhere((p) => p.id == empty.id).featured, isNull);
    });

    test('재생 기록이 생기면 대표곡이 바뀌어 다시 흘러나온다', () async {
      await DriftLibraryRepository(db)
          .addTracks([track('a', 'A곡', '가수'), track('b', 'B곡', '가수')]);
      final pl = await repo.create('모음');
      await repo.addTracks(['a', 'b'], pl.id);

      final seen = <String?>[];
      final sub = repo.watchPlaylists().listen(
        (l) => seen.add(l.firstWhere((p) => p.id == pl.id).featured?.id),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await play('b', 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(seen.first, 'a');
      expect(seen.last, 'b');
    });

    test('좋아요 목록은 항상 맨 앞에 있고, 곡을 담으면 곡 수가 센다', () async {
      await DriftLibraryRepository(db).addTracks([track('a', 'A곡', '가수')]);
      await repo.create('모음');
      var lists = await repo.watchPlaylists().first;
      expect(lists.first.isFavorites, isTrue);
      expect(lists.first.trackCount, 0);
      expect(lists.length, 2);

      await repo.addTrack('a', [Playlist.favoritesId]);
      lists = await repo.watchPlaylists().first;
      expect(lists.first.trackCount, 1);
      expect(lists.first.trackIds, {'a'});
      expect(lists.first.featured?.id, 'a');
    });

    test('watchTracks는 담은 순서로 곡을 돌려주고 빼면 사라진다', () async {
      await DriftLibraryRepository(db)
          .addTracks([track('a', 'A곡', '가수'), track('b', 'B곡', '가수')]);
      final pl = await repo.create('모음');
      await repo.addTracks(['b', 'a'], pl.id);
      expect((await repo.watchTracks(pl.id).first).map((t) => t.id), [
        'b',
        'a',
      ]);
      await repo.removeTrack('b', pl.id);
      expect((await repo.watchTracks(pl.id).first).map((t) => t.id), ['a']);
    });

    test('이름 바꾸기 · 삭제 (담긴 곡은 보관함에 남는다)', () async {
      final library = DriftLibraryRepository(db);
      await library.addTracks([track('a', 'A곡', '가수')]);
      final pl = await repo.create('모음', colorIndex: 1);
      expect((await userLists()).single.colorIndex, 1);
      await repo.addTrack('a', [pl.id]);

      await repo.rename(pl.id, '새 이름');
      expect((await userLists()).single.name, '새 이름');

      await repo.delete(pl.id);
      expect(await userLists(), isEmpty);
      expect(await repo.watchTracks(pl.id).first, isEmpty);
      expect(await library.watchTracks().first, hasLength(1));
    });

    test('카드 색을 정하고 null로 자동으로 되돌린다', () async {
      final pl = await repo.create('모음');
      expect((await userLists()).single.colorIndex, isNull);
      await repo.setColor(pl.id, 2);
      expect((await userLists()).single.colorIndex, 2);
      await repo.setColor(pl.id, null);
      expect((await userLists()).single.colorIndex, isNull);
    });
  });
}
