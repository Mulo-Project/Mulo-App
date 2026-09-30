import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';

class DriftPlaylistRepository implements PlaylistRepository {
  DriftPlaylistRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Playlist>> watchPlaylists() {
    final count = _db.playlistTracks.trackId.count();
    final query =
        _db.select(_db.playlists).join([
            leftOuterJoin(
              _db.playlistTracks,
              _db.playlistTracks.playlistId.equalsExp(_db.playlists.id),
            ),
          ])
          ..addColumns([count])
          ..groupBy([_db.playlists.id])
          ..orderBy([OrderingTerm.asc(_db.playlists.createdAt)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          Playlist(
            id: r.readTable(_db.playlists).id,
            name: r.readTable(_db.playlists).name,
            trackCount: r.read(count) ?? 0,
          ),
      ],
    );
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
}
