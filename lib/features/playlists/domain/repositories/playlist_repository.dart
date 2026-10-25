import '../../../library/domain/entities/track.dart';
import '../entities/playlist.dart';

/// 재생목록 저장소.
abstract interface class PlaylistRepository {
  /// 좋아요 목록이 맨 앞, 나머지는 사용자가 정한 순서(정하지 않았으면 만든 순서). 바뀔 때마다 다시 흘려보낸다.
  Stream<List<Playlist>> watchPlaylists();

  /// 좋아요 목록을 뺀 재생목록의 순서를 [playlistIds] 순서로 정한다 (좋아요 목록은 늘 맨 앞).
  Future<void> reorder(List<String> playlistIds);

  /// 재생목록에 담긴 곡 (담은 순서). 바뀔 때마다 다시 흘려보낸다.
  Stream<List<Track>> watchTracks(String playlistId);

  /// 새 재생목록을 만든다.
  Future<Playlist> create(String name);

  /// 이름을 바꾼다 (좋아요 목록은 바꿀 수 없다).
  Future<void> rename(String playlistId, String name);

  /// 재생목록을 지운다. 담긴 곡은 보관함에 남는다 (좋아요 목록은 지울 수 없다).
  Future<void> delete(String playlistId);

  /// 곡을 재생목록들에 넣는다. 이미 들어 있으면 건너뛴다.
  Future<void> addTrack(String trackId, Iterable<String> playlistIds);

  /// 곡들을 재생목록 하나에 넣는다. 이미 들어 있으면 건너뛴다.
  Future<void> addTracks(Iterable<String> trackIds, String playlistId);

  /// 곡을 재생목록에서 뺀다 (곡 자체는 보관함에 남는다).
  Future<void> removeTrack(String trackId, String playlistId);
}
