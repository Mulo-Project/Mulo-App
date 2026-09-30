import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/library_repository.dart';

class DriftLibraryRepository implements LibraryRepository {
  DriftLibraryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Track>> watchTracks() =>
      (_db.select(_db.tracks)..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
          .watch()
          .map((rows) => rows.map(_toTrack).toList());

  @override
  Future<int> addTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return 0;
    final before = await _count();
    await _db.batch((b) {
      b.insertAll(_db.tracks, [
        for (final t in tracks) _toRow(t),
      ], mode: InsertMode.insertOrIgnore);
    });
    return await _count() - before;
  }

  Future<int> _count() async {
    final count = _db.tracks.id.count();
    final row = await (_db.selectOnly(
      _db.tracks,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  static Track _toTrack(TrackRow r) => Track(
    id: r.id,
    title: r.title,
    artist: r.artist,
    album: r.album,
    duration: Duration(milliseconds: r.durationMs),
    addedAt: r.addedAt,
    uri: r.uri,
    source: TrackSource.values.asNameMap()[r.source] ?? TrackSource.device,
  );

  static TracksCompanion _toRow(Track t) => TracksCompanion.insert(
    id: t.id,
    title: t.title,
    artist: t.artist,
    album: t.album,
    durationMs: t.duration.inMilliseconds,
    uri: t.uri,
    source: t.source.name,
    addedAt: t.addedAt,
  );
}
