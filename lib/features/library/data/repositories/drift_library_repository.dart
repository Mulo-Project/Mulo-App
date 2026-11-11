import 'dart:io';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/hidden_track.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_info.dart';
import '../../domain/repositories/library_repository.dart';

class DriftLibraryRepository implements LibraryRepository {
  DriftLibraryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Track>> watchTracks() =>
      (_db.select(_db.tracks)
            ..where((t) => t.hidden.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
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
      // 폴더를 빼서 숨겨 둔 곡은 다시 찾으면 숨김만 푼다 (기록은 그대로).
      for (final t in tracks) {
        b.update(
          _db.tracks,
          const TracksCompanion(hidden: Value(false)),
          where: (r) => r.uri.equals(t.uri) & r.hidden.equals(true),
        );
      }
      // 기기에서 불러온 곡은 다시 찾을 때마다 파일 날짜로 추가일을 맞춘다 (전에는 찾은 시각이 들어가 같은 날짜가 됐다).
      for (final t in tracks.where((t) => t.source == TrackSource.device)) {
        b.update(
          _db.tracks,
          TracksCompanion(addedAt: Value(t.addedAt)),
          where: (r) => r.uri.equals(t.uri) & r.source.equals('device'),
        );
      }
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
  Future<void> hide(String trackId) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(trackId))).write(
        const TracksCompanion(hidden: Value(true)),
      );

  @override
  Future<int> hiddenCount() async {
    final count = _db.tracks.id.count();
    final row =
        await (_db.selectOnly(_db.tracks)
              ..addColumns([count])
              ..where(_db.tracks.hidden.equals(true)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<List<HiddenTrack>> hiddenTracks() async {
    final rows =
        await (_db.select(_db.tracks)
              ..where((t) => t.hidden.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.title)]))
            .get();
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r.id];
    final keys = [for (final id in ids) 'track:$id'];

    final plays = <String, (int, DateTime)>{};
    for (final p in await (_db.select(
      _db.plays,
    )..where((p) => p.trackId.isIn(ids))).get()) {
      final old = plays[p.trackId];
      plays[p.trackId] = (
        (old?.$1 ?? 0) + 1,
        old == null || p.playedAt.isAfter(old.$2) ? p.playedAt : old.$2,
      );
    }
    final inPlaylists = <String, int>{};
    for (final p in await (_db.select(
      _db.playlistTracks,
    )..where((p) => p.trackId.isIn(ids))).get()) {
      inPlaylists[p.trackId] = (inPlaylists[p.trackId] ?? 0) + 1;
    }
    final covers = {
      for (final c in await (_db.select(
        _db.covers,
      )..where((c) => c.key.isIn(keys))).get())
        c.key,
    };
    final lyrics = {
      for (final l in await (_db.select(
        _db.lyricsFiles,
      )..where((l) => l.trackId.isIn(ids))).get())
        l.trackId,
    };
    return [
      for (final r in rows)
        HiddenTrack(
          track: _toTrack(r),
          playCount: plays[r.id]?.$1 ?? 0,
          lastPlayedAt: plays[r.id]?.$2,
          playlistCount: inPlaylists[r.id] ?? 0,
          hasCover: covers.contains('track:${r.id}'),
          hasLyrics: lyrics.contains(r.id),
        ),
    ];
  }

  @override
  Future<int> purgeHidden({Set<String>? ids}) async {
    if (ids != null && ids.isEmpty) return 0;
    final files = <String>[];
    final purged = await _db.transaction(() async {
      final query = _db.select(_db.tracks)
        ..where((t) => t.hidden.equals(true));
      if (ids != null) query.where((t) => t.id.isIn(ids));
      return _purgeRows([for (final t in await query.get()) t.id], files);
    });
    for (final path in files) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } on FileSystemException {
        // 못 지워도 기록은 이미 지웠다.
      }
    }
    return purged;
  }

  Future<int> _purgeRows(List<String> ids, List<String> files) async {
    if (ids.isEmpty) return 0;
    final keys = [for (final id in ids) 'track:$id'];
    for (final c in await (_db.select(
      _db.covers,
    )..where((c) => c.key.isIn(keys))).get()) {
      if (c.path.isNotEmpty) files.add(c.path);
    }
    for (final l in await (_db.select(
      _db.lyricsFiles,
    )..where((l) => l.trackId.isIn(ids))).get()) {
      files.add(l.path);
    }
    await (_db.delete(_db.covers)..where((c) => c.key.isIn(keys))).go();
    await (_db.delete(_db.coverColors)..where((c) => c.key.isIn(keys))).go();
    await (_db.delete(
      _db.lyricsFiles,
    )..where((l) => l.trackId.isIn(ids))).go();
    await (_db.delete(
      _db.playlistTracks,
    )..where((p) => p.trackId.isIn(ids))).go();
    await (_db.delete(_db.plays)..where((p) => p.trackId.isIn(ids))).go();
    await (_db.delete(_db.tracks)..where((t) => t.id.isIn(ids))).go();
    return ids.length;
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
    final row =
        await (_db.selectOnly(_db.tracks)
              ..addColumns([count])
              ..where(_db.tracks.hidden.equals(false)))
            .getSingle();
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
    mime: r.mime,
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
    mime: Value(t.mime),
  );
}
