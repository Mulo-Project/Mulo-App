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
}
