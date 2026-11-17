import '../../../../core/database/native_db.dart';
import '../../domain/entities/hidden_track.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_info.dart';
import '../../domain/repositories/library_repository.dart';
import '../models/track_map.dart';

/// 보관함 저장소. DB는 네이티브가 쥐고 규칙(숨김 풀기 · 정렬 · 지울 때 함께 지울 것)도 네이티브가 가진다.
class NativeLibraryRepository implements LibraryRepository {
  NativeLibraryRepository(this._db);

  final NativeDb _db;

  @override
  Stream<List<Track>> watchTracks() => _db.watch({'tracks'}, () async {
    final rows = await _db.list('tracks');
    return [for (final r in rows) trackFromMap(r)];
  });

  @override
  Future<int> addTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return 0;
    return (await _db.call<int>('addTracks', {
          'tracks': [for (final t in tracks) trackToMap(t)],
        })) ??
        0;
  }

  @override
  Future<bool> updateInfo(String trackId, TrackInfo info) async =>
      (await _db.call<bool>('updateInfo', {
        'id': trackId,
        'title': info.title,
        'artist': info.artist,
        'album': info.album,
        'genre': info.genre,
      })) ??
      false;

  @override
  Future<void> hide(String trackId) => _db.call<void>('hide', {'id': trackId});

  @override
  Future<void> hideMany(Iterable<String> trackIds) {
    final ids = trackIds.toList();
    if (ids.isEmpty) return Future.value();
    return _db.call<void>('hideMany', {'ids': ids});
  }

  @override
  Future<int> hiddenCount() async => (await _db.call<int>('hiddenCount')) ?? 0;

  @override
  Future<List<HiddenTrack>> hiddenTracks() async {
    final rows = await _db.list('hiddenTracks');
    return [
      for (final r in rows)
        HiddenTrack(
          track: trackFromMap(r['track']! as Map),
          playCount: (r['playCount']! as num).toInt(),
          lastPlayedAt: r['lastPlayedAtSec'] == null
              ? null
              : dateOfSec(r['lastPlayedAtSec']),
          playlistCount: (r['playlistCount']! as num).toInt(),
          hasCover: r['hasCover']! as bool,
          hasLyrics: r['hasLyrics']! as bool,
        ),
    ];
  }

  @override
  Future<int> purgeHidden({Set<String>? ids}) async =>
      (await _db.call<int>('purgeHidden', {
        'ids': ids?.toList(),
      })) ??
      0;

  @override
  Future<void> delete(String trackId) =>
      _db.call<void>('deleteTrack', {'id': trackId});
}
