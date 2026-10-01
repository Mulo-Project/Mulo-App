import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../features/library/domain/entities/track.dart';
import 'sample_data.dart';

/// 디버그 빌드에서 화면을 샘플로 확인할 수 있게, 보관함이 비어 있으면
/// 샘플 곡 · 재생목록 · 재생 기록을 DB에 넣는다. 릴리스 빌드와 테스트에서는 부르지 않는다.
/// 실제 곡이 하나라도 있으면 아무것도 하지 않는다.
Future<void> seedSampleData(AppDatabase db, {DateTime? now}) async {
  final existing = await (db.select(db.tracks)..limit(1)).get();
  if (existing.isNotEmpty) return;

  final base = now ?? DateTime.now();
  final tracks = SampleData.tracks;

  await db.batch((b) {
    b.insertAll(db.tracks, [
      for (final t in tracks)
        TracksCompanion.insert(
          id: t.id,
          title: t.title,
          artist: t.artist,
          album: t.album,
          genre: Value(t.genre),
          durationMs: t.duration.inMilliseconds,
          uri: t.uri,
          source: TrackSource.download.name,
          addedAt: t.addedAt,
        ),
    ]);

    // 재생목록: 샘플 이름마다 곡을 몇 개씩 담는다.
    for (final (i, (name, _)) in SampleData.playlists.indexed) {
      final id = 'sample-pl${i + 1}';
      b.insert(
        db.playlists,
        PlaylistsCompanion.insert(
          id: id,
          name: name,
          createdAt: base.subtract(Duration(days: 10 - i)),
        ),
      );
      b.insertAll(db.playlistTracks, [
        for (var k = 0; k < 4 + i; k++)
          PlaylistTracksCompanion.insert(
            playlistId: id,
            trackId: tracks[(i * 3 + k) % tracks.length].id,
            addedAt: base.subtract(Duration(days: 9 - i)),
          ),
      ]);
    }

    // 재생 기록: 최근 2주에 걸쳐 곡을 고르게 섞어 40번.
    b.insertAll(db.plays, [
      for (var n = 0; n < 40; n++)
        PlaysCompanion.insert(
          trackId: tracks[(n * 5 + n ~/ 7) % tracks.length].id,
          playedAt: base.subtract(Duration(hours: n * 8 + (n % 3) * 2)),
          listenedMs: Value(tracks[n % tracks.length].duration.inMilliseconds),
        ),
    ]);
  });
}
