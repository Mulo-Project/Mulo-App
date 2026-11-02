import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';

class DriftPlaylistRepository implements PlaylistRepository {
  DriftPlaylistRepository(this._db);

  final AppDatabase _db;

  /// 담은 순서. 시각은 초 단위로만 저장되어 같은 초에 담은 곡끼리는 넣은 순서(rowid)로 가린다.
  static final _insertOrder = OrderingTerm.asc(
    const CustomExpression<int>('playlist_tracks.rowid'),
  );

  /// 재생목록 · 담긴 곡 · 곡 · 재생 기록 중 무엇이 바뀌어도 다시 계산한다.
  @override
  Stream<List<Playlist>> watchPlaylists() {
    final changes = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.playlists,
        _db.playlistTracks,
        _db.tracks,
        _db.plays,
      ]),
    );
    // 구독하자마자 한 번, 이후 바뀔 때마다. async* 로 쓰면 구독을 끊을 때
    // 다음 변경까지 cancel이 끝나지 않으므로 multi + asyncMap 으로 만든다.
    return Stream<void>.multi((c) {
      c.add(null);
      final sub = changes.listen(c.add);
      c.onCancel = sub.cancel;
    }).asyncMap((_) => _load());
  }

  Future<List<Playlist>> _load() async {
    // 사용자가 정한 순서, 같으면 만든 순서.
    final lists =
        await (_db.select(_db.playlists)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();

    // 재생목록 id → 담긴 곡 id (담은 순서). 곡 수는 보관함에 없는 곡(지워진 곡)도
    // 담은 기록 그대로 센다.
    final added =
        await (_db.select(_db.playlistTracks)..orderBy([
              (t) => OrderingTerm.asc(t.addedAt),
              (_) => _insertOrder,
            ]))
            .get();
    final ids = <String, List<String>>{};
    for (final r in added) {
      ids.putIfAbsent(r.playlistId, () => []).add(r.trackId);
    }

    // 곡 id → 곡, 곡 id → 들은 횟수.
    final trackRows = {
      for (final t in await (_db.select(
        _db.tracks,
      )..where((t) => t.hidden.equals(false))).get())
        t.id: t,
    };
    final plays = <String, int>{};
    final count = _db.plays.id.count();
    final counted =
        await (_db.selectOnly(_db.plays)
              ..addColumns([_db.plays.trackId, count])
              ..groupBy([_db.plays.trackId]))
            .get();
    for (final r in counted) {
      plays[r.read(_db.plays.trackId)!] = r.read(count) ?? 0;
    }

    Playlist build(String id, String name) {
      final members = ids[id] ?? const <String>[];
      return Playlist(
        id: id,
        name: name,
        trackCount: members.length,
        featured: _featured([
          for (final t in members)
            if (trackRows[t] != null) trackRows[t]!,
        ], plays),
        trackIds: members.toSet(),
      );
    }

    return [
      build(Playlist.favoritesId, ''),
      for (final row in lists) build(row.id, row.name),
    ];
  }

  /// 많이 들은 곡. 들은 기록이 없으면 가장 먼저 담은 곡. ([tracks]는 담은 순서)
  static PlaylistTrackPreview? _featured(
    List<TrackRow> tracks,
    Map<String, int> plays,
  ) {
    if (tracks.isEmpty) return null;
    var best = tracks.first;
    for (final t in tracks) {
      if ((plays[t.id] ?? 0) > (plays[best.id] ?? 0)) best = t;
    }
    return PlaylistTrackPreview(
      id: best.id,
      title: best.title,
      artist: best.artist,
      genre: best.genre,
    );
  }

  @override
  Stream<List<Track>> watchTracks(String playlistId) {
    final query =
        _db.select(_db.playlistTracks).join([
            innerJoin(
              _db.tracks,
              _db.tracks.id.equalsExp(_db.playlistTracks.trackId),
            ),
          ])
          ..where(
            _db.playlistTracks.playlistId.equals(playlistId) &
                _db.tracks.hidden.equals(false),
          )
          ..orderBy([
            OrderingTerm.asc(_db.playlistTracks.addedAt),
            _insertOrder,
          ]);
    return query.watch().map(
      (rows) => [for (final r in rows) _toTrack(r.readTable(_db.tracks))],
    );
  }

  static Track _toTrack(TrackRow r) => Track(
    id: r.id,
    title: r.title,
    artist: r.artist,
    album: r.album,
    genre: r.genre,
    duration: Duration(milliseconds: r.durationMs),
    addedAt: r.addedAt,
    uri: r.uri,
    folder: r.folder,
    source: TrackSource.values.asNameMap()[r.source] ?? TrackSource.device,
  );

  @override
  Future<Playlist> create(String name) async {
    final now = DateTime.now();
    final id = 'pl${now.microsecondsSinceEpoch}';
    // 새 재생목록은 순서의 맨 뒤로 간다.
    final maxOrder = _db.playlists.sortOrder.max();
    final top = await (_db.selectOnly(
      _db.playlists,
    )..addColumns([maxOrder])).getSingle();
    final next = (top.read(maxOrder) ?? 0) + 1;
    await _db
        .into(_db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            id: id,
            name: name,
            createdAt: now,
            sortOrder: Value(next),
          ),
        );
    return Playlist(id: id, name: name);
  }

  @override
  Future<void> reorder(List<String> playlistIds) => _db.transaction(() async {
    for (final (i, id) in playlistIds.indexed) {
      await (_db.update(_db.playlists)..where((t) => t.id.equals(id))).write(
        PlaylistsCompanion(sortOrder: Value(i + 1)),
      );
    }
  });

  @override
  Future<void> rename(String playlistId, String name) =>
      (_db.update(_db.playlists)..where((t) => t.id.equals(playlistId))).write(
        PlaylistsCompanion(name: Value(name)),
      );

  @override
  Future<void> delete(String playlistId) => _db.transaction(() async {
    await (_db.delete(
      _db.playlistTracks,
    )..where((t) => t.playlistId.equals(playlistId))).go();
    await (_db.delete(
      _db.covers,
    )..where((t) => t.key.equals('playlist:$playlistId'))).go();
    await (_db.delete(
      _db.playlists,
    )..where((t) => t.id.equals(playlistId))).go();
  });

  @override
  Future<void> addTrack(String trackId, Iterable<String> playlistIds) async {
    final now = DateTime.now();
    await _db.batch((b) {
      b.insertAll(_db.playlistTracks, [
        for (final id in playlistIds)
          PlaylistTracksCompanion.insert(
            playlistId: id,
            trackId: trackId,
            addedAt: now,
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }

  @override
  Future<void> addTracks(Iterable<String> trackIds, String playlistId) async {
    final now = DateTime.now();
    await _db.batch((b) {
      // 담은 순서가 남도록 곡마다 시각을 조금씩 늦춘다.
      b.insertAll(_db.playlistTracks, [
        for (final (i, id) in trackIds.indexed)
          PlaylistTracksCompanion.insert(
            playlistId: playlistId,
            trackId: id,
            addedAt: now.add(Duration(microseconds: i)),
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }

  @override
  Future<void> removeTrack(String trackId, String playlistId) =>
      (_db.delete(_db.playlistTracks)..where(
            (t) => t.trackId.equals(trackId) & t.playlistId.equals(playlistId),
          ))
          .go();
}
