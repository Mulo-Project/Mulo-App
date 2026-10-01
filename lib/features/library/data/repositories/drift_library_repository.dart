import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_info.dart';
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
      // 폴더 칸이 생기기 전에 넣은 곡은 다시 찾을 때 폴더를 채운다.
      for (final t in tracks.where((t) => t.folder.isNotEmpty)) {
        b.update(
          _db.tracks,
          TracksCompanion(folder: Value(t.folder)),
          where: (r) => r.uri.equals(t.uri) & r.folder.equals(''),
        );
      }
    });
    return await _count() - before;
  }

  @override
  Future<bool> updateInfo(String trackId, TrackInfo info) async {
    final changed =
        await (_db.update(
          _db.tracks,
        )..where((t) => t.id.equals(trackId))).write(
          TracksCompanion(
            title: Value(info.title),
            artist: Value(info.artist),
            album: Value(info.album),
            genre: Value(info.genre),
          ),
        );
    return changed > 0;
  }

  @override
  Future<void> delete(String trackId) => _db.transaction(() async {
    await (_db.delete(_db.tracks)..where((t) => t.id.equals(trackId))).go();
    await (_db.delete(
      _db.playlistTracks,
    )..where((t) => t.trackId.equals(trackId))).go();
    await (_db.delete(_db.plays)..where((t) => t.trackId.equals(trackId))).go();
    await (_db.delete(
      _db.covers,
    )..where((t) => t.key.equals('track:$trackId'))).go();
  });

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
    genre: r.genre,
    duration: Duration(milliseconds: r.durationMs),
    addedAt: r.addedAt,
    uri: r.uri,
    folder: r.folder,
    source: TrackSource.values.asNameMap()[r.source] ?? TrackSource.device,
  );

  static TracksCompanion _toRow(Track t) => TracksCompanion.insert(
    id: t.id,
    title: t.title,
    artist: t.artist,
    album: t.album,
    genre: Value(t.genre),
    durationMs: t.duration.inMilliseconds,
    uri: t.uri,
    folder: Value(t.folder),
    source: t.source.name,
    addedAt: t.addedAt,
  );
}
