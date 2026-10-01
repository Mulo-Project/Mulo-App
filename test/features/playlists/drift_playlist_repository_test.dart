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

  test('removeTrack은 그 재생목록에서만 곡을 뺀다', () async {
    final a = await repo.create('A');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final b = await repo.create('B');
    await repo.addTrack('t1', [a.id, b.id]);
    await repo.addTrack('t2', [a.id]);

    await repo.removeTrack('t1', a.id);

    final lists = await repo.watchPlaylists().first;
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

    test('많이 들은 곡을 많은 순으로, 들은 적 없는 곡은 뺀다', () async {
      await DriftLibraryRepository(db).addTracks([
        track('a', 'A곡', '가수1'),
        track('b', 'B곡', '가수1'),
        track('c', 'C곡', '가수2'),
        track('d', 'D곡', '가수3'),
        track('e', 'E곡', '가수3'),
      ]);
      final pl = await repo.create('모음');
      await repo.addTrack('a', [pl.id]);
      await repo.addTrack('b', [pl.id]);
      await repo.addTrack('c', [pl.id]);
      await repo.addTrack('d', [pl.id]);
      await repo.addTrack('e', [pl.id]);
      await play('b', 5);
      await play('a', 2);
      await play('c', 2);
      await play('d', 1);
      await play('zzz', 9); // 이 재생목록에 없는 곡은 세지 않는다.

      final got = (await repo.watchPlaylists().first).single;
      // 횟수 많은 순, 같으면 제목순 → b(5), a(2), c(2). d(1)는 3개 제한에서 빠진다.
      expect(got.topTracks.map((t) => t.id), ['b', 'a', 'c']);
    });

    test('들은 기록이 없으면 곡은 비고, 주요 아티스트는 곡이 많은 순 (모르는 아티스트 제외)', () async {
      await DriftLibraryRepository(db).addTracks([
        track('a', 'A', '가수1'),
        track('b', 'B', '가수2'),
        track('c', 'C', '가수2'),
        track('d', 'D', ''),
      ]);
      final pl = await repo.create('모음');
      await repo.addTrack('a', [pl.id]);
      await repo.addTrack('b', [pl.id]);
      await repo.addTrack('c', [pl.id]);
      await repo.addTrack('d', [pl.id]);

      final got = (await repo.watchPlaylists().first).single;
      expect(got.topTracks, isEmpty);
      expect(got.topArtists, ['가수2', '가수1']);
      expect(got.trackCount, 4);
    });

    test('재생 기록이 생기면 요약이 다시 흘러나온다', () async {
      await DriftLibraryRepository(db).addTracks([track('a', 'A곡', '가수')]);
      final pl = await repo.create('모음');
      await repo.addTrack('a', [pl.id]);

      final seen = <int>[];
      final sub = repo.watchPlaylists().listen(
        (l) => seen.add(l.single.topTracks.length),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await play('a', 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(seen.first, 0);
      expect(seen.last, 1);
    });

    test('카드 색을 정하고 null로 자동으로 되돌린다', () async {
      final pl = await repo.create('모음');
      expect((await repo.watchPlaylists().first).single.colorIndex, isNull);
      await repo.setColor(pl.id, 2);
      expect((await repo.watchPlaylists().first).single.colorIndex, 2);
      await repo.setColor(pl.id, null);
      expect((await repo.watchPlaylists().first).single.colorIndex, isNull);
    });
  });
}
