import '../../../../core/database/native_db.dart';
import '../../../library/data/models/track_map.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';

/// 재생목록 저장소. 곡 수 · 대표곡 · 담은 순서 같은 규칙은 네이티브가 계산해 돌려준다.
class NativePlaylistRepository implements PlaylistRepository {
  NativePlaylistRepository(this._db);

  final NativeDb _db;

  /// 재생목록 · 담긴 곡 · 곡 · 재생 기록 중 무엇이 바뀌어도 다시 읽는다.
  @override
  Stream<List<Playlist>> watchPlaylists() => _db.watch({
    'playlists',
    'playlist_tracks',
    'tracks',
    'plays',
  }, () async {
    final rows = await _db.list('playlists');
    return [
      for (final r in rows)
        Playlist(
          id: r['id']! as String,
          name: r['name']! as String,
          trackCount: (r['trackCount']! as num).toInt(),
          featured: _featured(r['featured']),
          trackIds: {for (final id in r['trackIds']! as List) id! as String},
        ),
    ];
  });

  static PlaylistTrackPreview? _featured(Object? m) {
    if (m is! Map) return null;
    return PlaylistTrackPreview(
      id: m['id']! as String,
      title: m['title']! as String,
      artist: m['artist']! as String,
      genre: m['genre']! as String,
    );
  }

  @override
  Stream<List<Track>> watchTracks(String playlistId) =>
      _db.watch({'playlist_tracks', 'tracks'}, () async {
        final rows = await _db.list('playlistTracks', {
          'playlistId': playlistId,
        });
        return [for (final r in rows) trackFromMap(r)];
      });

  @override
  Future<Playlist> create(String name) async {
    final r = await _db.map('createPlaylist', {'name': name});
    return Playlist(id: r['id']! as String, name: r['name']! as String);
  }

  @override
  Future<void> reorder(List<String> playlistIds) =>
      _db.call<void>('reorderPlaylists', {'ids': playlistIds});

  @override
  Future<void> rename(String playlistId, String name) =>
      _db.call<void>('renamePlaylist', {'id': playlistId, 'name': name});

  @override
  Future<void> delete(String playlistId) =>
      _db.call<void>('deletePlaylist', {'id': playlistId});

  @override
  Future<void> addTrack(String trackId, Iterable<String> playlistIds) =>
      _db.call<void>('addTrackToPlaylists', {
        'trackId': trackId,
        'playlistIds': playlistIds.toList(),
      });

  @override
  Future<void> addTracks(Iterable<String> trackIds, String playlistId) =>
      _db.call<void>('addTracksToPlaylist', {
        'trackIds': trackIds.toList(),
        'playlistId': playlistId,
      });

  @override
  Future<void> removeTrack(String trackId, String playlistId) =>
      _db.call<void>('removeTrackFromPlaylist', {
        'trackId': trackId,
        'playlistId': playlistId,
      });
}
