import '../entities/playlist.dart';

/// 재생목록 저장소.
abstract interface class PlaylistRepository {
  /// 만든 순서. 바뀔 때마다 다시 흘려보낸다.
  Stream<List<Playlist>> watchPlaylists();

  /// 새 재생목록을 만든다.
  Future<Playlist> create(String name);

  /// 곡을 재생목록들에 넣는다. 이미 들어 있으면 건너뛴다.
  Future<void> addTrack(String trackId, Iterable<String> playlistIds);
}
