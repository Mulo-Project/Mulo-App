import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';

class DriftPlaylistRepository implements PlaylistRepository {
  DriftPlaylistRepository(this._db);

  final AppDatabase _db;

  /// 카드 요약에 보여 줄 개수.
  static const _summarySize = 3;

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
    final lists = await (_db.select(
      _db.playlists,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

    // 재생목록 id → 담긴 곡.
    final members = <String, List<TrackRow>>{};
    final joined = await _db.select(_db.playlistTracks).join([
      innerJoin(
        _db.tracks,
        _db.tracks.id.equalsExp(_db.playlistTracks.trackId),
      ),
    ]).get();
    for (final r in joined) {
      members
          .putIfAbsent(r.readTable(_db.playlistTracks).playlistId, () => [])
          .add(r.readTable(_db.tracks));
    }

    // 곡 id → 들은 횟수.
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

    // 곡 수는 보관함에 없는 곡(지워진 곡)을 빼지 않고 담은 기록 그대로 센다.
    final totals = <String, int>{};
    final all = await _db.select(_db.playlistTracks).get();
    for (final r in all) {
      totals[r.playlistId] = (totals[r.playlistId] ?? 0) + 1;
    }

    return [
      for (final row in lists)
        Playlist(
          id: row.id,
          name: row.name,
          trackCount: totals[row.id] ?? 0,
          colorIndex: row.colorIndex,
          topTracks: _topTracks(members[row.id] ?? const [], plays),
          topArtists: _topArtists(members[row.id] ?? const []),
        ),
    ];
  }

  static List<PlaylistTrackPreview> _topTracks(
    List<TrackRow> tracks,
    Map<String, int> plays,
  ) {
    final heard = tracks.where((t) => (plays[t.id] ?? 0) > 0).toList()
      ..sort((a, b) {
        final byPlays = plays[b.id]!.compareTo(plays[a.id]!);
        return byPlays != 0 ? byPlays : a.title.compareTo(b.title);
      });
    return [
      for (final t in heard.take(_summarySize))
        PlaylistTrackPreview(id: t.id, title: t.title, artist: t.artist),
    ];
  }

  static List<String> _topArtists(List<TrackRow> tracks) {
    final counts = <String, int>{};
    for (final t in tracks) {
      if (t.artist.isEmpty) continue;
      counts[t.artist] = (counts[t.artist] ?? 0) + 1;
    }
    final names = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return names.take(_summarySize).toList();
  }

  @override
  Future<Playlist> create(String name) async {
    final now = DateTime.now();
    final id = 'pl${now.microsecondsSinceEpoch}';
    await _db
        .into(_db.playlists)
        .insert(PlaylistsCompanion.insert(id: id, name: name, createdAt: now));
    return Playlist(id: id, name: name);
  }

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
  Future<void> removeTrack(String trackId, String playlistId) =>
      (_db.delete(_db.playlistTracks)..where(
            (t) => t.trackId.equals(trackId) & t.playlistId.equals(playlistId),
          ))
          .go();

  @override
  Future<void> setColor(String playlistId, int? colorIndex) =>
      (_db.update(_db.playlists)..where((t) => t.id.equals(playlistId))).write(
        PlaylistsCompanion(colorIndex: Value(colorIndex)),
      );
}
