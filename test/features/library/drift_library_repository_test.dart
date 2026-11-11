import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/library/data/repositories/drift_library_repository.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/entities/track_info.dart';

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

  test('영상 곡 표시는 DB에 저장돼 다시 읽어도 영상이다', () async {
    await repo.addTracks([
      Track(
        id: 'v',
        title: 'Clip',
        artist: '',
        album: '',
        duration: const Duration(minutes: 1),
        uri: 'content://media/external/downloads/1',
        addedAt: DateTime(2026, 9, 1),
        hasVideo: true,
      ),
      _t('a', 'u1', 2),
    ]);
    final list = {for (final t in await repo.watchTracks().first) t.id: t};
    expect(list['v']!.isVideo, isTrue);
    expect(list['a']!.isVideo, isFalse);
  });

  test('updateInfo는 정보를 바꾸고, 없는 곡이면 false', () async {
    await repo.addTracks([_t('a', 'u1', 1)]);
    const info = TrackInfo(
      title: '새 제목',
      artist: '가수',
      album: '앨범',
      genre: '재즈',
    );
    expect(await repo.updateInfo('a', info), isTrue);
    final t = (await repo.watchTracks().first).single;
    expect([t.title, t.artist, t.album, t.genre], ['새 제목', '가수', '앨범', '재즈']);
    expect(t.uri, 'u1');
    expect(await repo.updateInfo('nope', info), isFalse);
  });

  test('다시 불러와도 고친 정보는 덮어쓰지 않는다', () async {
    await repo.addTracks([_t('a', 'u1', 1)]);
    await repo.updateInfo('a', const TrackInfo(title: '고침'));
    await repo.addTracks([_t('a', 'u1', 1)]);
    expect((await repo.watchTracks().first).single.title, '고침');
  });

  test('delete는 곡과 재생목록 · 재생 기록 · 커버 기록을 함께 지운다', () async {
    await repo.addTracks([_t('a', 'u1', 1), _t('b', 'u2', 2)]);
    await db
        .into(db.playlistTracks)
        .insert(
          PlaylistTracksCompanion.insert(
            playlistId: 'p',
            trackId: 'a',
            addedAt: DateTime(2026, 9, 1),
          ),
        );
    await db
        .into(db.plays)
        .insert(PlaysCompanion.insert(trackId: 'a', playedAt: DateTime(2026)));
    await db
        .into(db.covers)
        .insert(CoversCompanion.insert(key: 'track:a', path: '/x.png'));

    await repo.delete('a');

    expect((await repo.watchTracks().first).map((t) => t.id), ['b']);
    expect(await db.select(db.playlistTracks).get(), isEmpty);
    expect(await db.select(db.plays).get(), isEmpty);
    expect(await db.select(db.covers).get(), isEmpty);
  });

  test('hide는 보관함에서만 숨기고 기록은 남기며, 다시 찾으면 숨김만 푼다', () async {
    await repo.addTracks([_t('a', 'u1', 1), _t('b', 'u2', 2)]);
    await db
        .into(db.plays)
        .insert(PlaysCompanion.insert(trackId: 'a', playedAt: DateTime(2026)));
    await repo.hide('a');
    expect((await repo.watchTracks().first).map((t) => t.id), ['b']);
    expect(await db.select(db.plays).get(), hasLength(1));
    // 다시 찾으면 새로 추가된 것으로 세고, 같은 id의 기록이 그대로 붙는다.
    expect(await repo.addTracks([_t('a', 'u1', 1)]), 1);
    expect((await repo.watchTracks().first).map((t) => t.id), ['b', 'a']);
    expect(await db.select(db.plays).get(), hasLength(1));
  });

  test('purgeHidden은 숨긴 곡의 기록만 모두 지우고 보이는 곡은 건드리지 않는다', () async {
    await repo.addTracks([_t('a', 'u1', 1), _t('b', 'u2', 2)]);
    for (final id in ['a', 'b']) {
      await db
          .into(db.plays)
          .insert(PlaysCompanion.insert(trackId: id, playedAt: DateTime(2026)));
    }
    await repo.hide('a');
    expect(await repo.hiddenCount(), 1);
    expect(await repo.purgeHidden(), 1);
    expect(await repo.hiddenCount(), 0);
    expect((await db.select(db.plays).get()).map((p) => p.trackId), ['b']);
    expect((await repo.watchTracks().first).map((t) => t.id), ['b']);
    expect(await repo.purgeHidden(), 0);
  });

  test('hiddenTracks는 숨긴 곡만 돌려주고 purgeHidden(ids)는 고른 숨긴 곡만 지운다', () async {
    await repo.addTracks([
      _t('a', 'u1', 1),
      _t('b', 'u2', 2),
      _t('c', 'u3', 3),
    ]);
    for (final id in ['a', 'b', 'c']) {
      await db
          .into(db.plays)
          .insert(PlaysCompanion.insert(trackId: id, playedAt: DateTime(2026)));
    }
    await repo.hide('a');
    await repo.hide('b');
    final hidden = await repo.hiddenTracks();
    expect(hidden.map((t) => t.track.id).toSet(), {'a', 'b'});
    expect(hidden.first.playCount, 1);
    expect(hidden.first.lastPlayedAt, DateTime(2026));
    expect(hidden.first.hasCover, isFalse);
    // 보이는 곡(c)은 ids에 있어도 건드리지 않고, 빈 집합은 아무것도 지우지 않는다.
    expect(await repo.purgeHidden(ids: {}), 0);
    expect(await repo.purgeHidden(ids: {'a', 'c'}), 1);
    expect((await repo.hiddenTracks()).map((t) => t.track.id), ['b']);
    expect(
      (await db.select(db.plays).get()).map((p) => p.trackId).toSet(),
      {'b', 'c'},
    );
    expect(await repo.purgeHidden(), 1);
    expect(await repo.hiddenTracks(), isEmpty);
  });
}
