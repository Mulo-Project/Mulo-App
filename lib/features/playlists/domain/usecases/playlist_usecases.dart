import '../../../../core/usecase/usecase.dart';
import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';

/// 재생목록 구독.
class WatchPlaylists implements StreamUseCase<List<Playlist>, NoParams> {
  const WatchPlaylists(this._repo);

  final PlaylistRepository _repo;

  @override
  Stream<List<Playlist>> call(NoParams params) => _repo.watchPlaylists();
}

/// 재생목록 만들기. 이름은 앞뒤 공백을 지우고, 비어 있으면 만들지 않는다 (null).
class CreatePlaylist implements UseCase<Playlist?, String> {
  const CreatePlaylist(this._repo);

  final PlaylistRepository _repo;

  @override
  Future<Playlist?> call(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return _repo.create(trimmed);
  }
}

class AddTrackToPlaylistsParams {
  const AddTrackToPlaylistsParams(this.trackId, this.playlistIds);

  final String trackId;
  final Set<String> playlistIds;
}

/// 곡을 재생목록들에 넣기.
class AddTrackToPlaylists implements UseCase<void, AddTrackToPlaylistsParams> {
  const AddTrackToPlaylists(this._repo);

  final PlaylistRepository _repo;

  @override
  Future<void> call(AddTrackToPlaylistsParams p) =>
      _repo.addTrack(p.trackId, p.playlistIds);
}
