import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// 네이티브가 받아서 저장한 곡을 보관함 DB(drift)에 넣는다 (곡 · 재생목록 · 커버 · 색 · 가사). 값은 네이티브가 정해서 넘긴다.
/// 같은 곡을 두 번 받아도(앱이 꺼졌다 켜져 다시 넘겨 받는 경우) 한 번만 들어간다.
class DriftDownloadRegistrar {
  DriftDownloadRegistrar(this._db);

  final AppDatabase _db;

  Future<void> register(Map<String, Object?> r) async {
    final trackId = r['trackId']! as String;
    final uri = r['uri']! as String;
    final addedAt = DateTime.fromMillisecondsSinceEpoch(
      (r['addedAtSec']! as num).toInt() * 1000,
    );
    final cover = r['cover'];
    final color = r['color'] as num?;
    final lyricsPath = r['lyricsPath'] as String?;
    await _db.transaction(() async {
      await _db
          .into(_db.tracks)
          .insert(
            TracksCompanion.insert(
              id: trackId,
              title: r['title']! as String,
              artist: r['artist']! as String,
              album: r['album']! as String,
              genre: Value(r['genre']! as String),
              durationMs: (r['durationMs']! as num).toInt(),
              uri: uri,
              folder: Value(r['folder']! as String),
              source: 'download',
              addedAt: addedAt,
              mime: Value(r['mime']! as String),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      // 불러오는 폴더에서 빼서 숨겨 둔 같은 곡이면 숨김만 푼다.
      await (_db.update(_db.tracks)
            ..where((t) => t.uri.equals(uri) & t.hidden.equals(true)))
          .write(const TracksCompanion(hidden: Value(false)));
      final playlists = (r['playlistIds'] as List<Object?>? ?? const [])
          .cast<String>();
      for (final (i, playlistId) in playlists.indexed) {
        await _db
            .into(_db.playlistTracks)
            .insert(
              PlaylistTracksCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                addedAt: addedAt.add(Duration(seconds: i)),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      if (cover is Map) {
        double num_(String k, double d) => (cover[k] as num?)?.toDouble() ?? d;
        await _db
            .into(_db.covers)
            .insert(
              CoversCompanion.insert(
                key: 'track:$trackId',
                path: (cover['path'] as String?) ?? '',
                url: Value(cover['url'] as String?),
                scale: Value(num_('scale', 1)),
                dx: Value(num_('dx', 0)),
                dy: Value(num_('dy', 0)),
                rotation: Value(num_('rotation', 0)),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
      if (color != null) {
        await _db
            .into(_db.coverColors)
            .insert(
              CoverColorsCompanion.insert(
                key: 'track:$trackId',
                color: color.toInt(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
      if (lyricsPath != null) {
        await _db
            .into(_db.lyricsFiles)
            .insert(
              LyricsFilesCompanion.insert(
                trackId: trackId,
                path: lyricsPath,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }
}
