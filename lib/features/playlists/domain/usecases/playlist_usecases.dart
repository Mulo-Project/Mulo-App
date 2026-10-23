import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';

/// 재생목록 구독.
class WatchPlaylists implements StreamUseCase<List<Playlist>, NoParams> {
  const WatchPlaylists(this._repo);

  final PlaylistRepository _repo;

  @override
  Stream<List<Playlist>> call(NoParams params) => _repo.watchPlaylists();
}

/// 재생목록 하나에 담긴 곡 구독.
class WatchPlaylistTracks implements StreamUseCase<List<Track>, String> {
  const WatchPlaylistTracks(this._repo);

  final PlaylistRepository _repo;

  @override
  Stream<List<Track>> call(String playlistId) => _repo.watchTracks(playlistId);
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

class RenamePlaylistParams {
  const RenamePlaylistParams(this.playlistId, this.name);

  final String playlistId;
  final String name;
}

/// 재생목록 이름 바꾸기. 비어 있거나 좋아요 목록이면 바꾸지 않고 false.
class RenamePlaylist implements UseCase<bool, RenamePlaylistParams> {
  const RenamePlaylist(this._repo);

  final PlaylistRepository _repo;

  @override
  Future<bool> call(RenamePlaylistParams p) async {
    final trimmed = p.name.trim();
    if (trimmed.isEmpty || p.playlistId == Playlist.favoritesId) return false;
    await _repo.rename(p.playlistId, trimmed);
    return true;
  }
}

/// 재생목록 지우기 (곡은 보관함에 남는다). 좋아요 목록이면 지우지 않고 false.
class DeletePlaylist implements UseCase<bool, String> {
  const DeletePlaylist(this._repo);

  final PlaylistRepository _repo;

  @override
  Future<bool> call(String playlistId) async {
    if (playlistId == Playlist.favoritesId) return false;
    await _repo.delete(playlistId);
    return true;
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

class AddTracksToPlaylistParams {
  const AddTracksToPlaylistParams(this.trackIds, this.playlistId);

  final Set<String> trackIds;
  final String playlistId;
}

/// 곡들을 재생목록 하나에 넣기.
class AddTracksToPlaylist implements UseCase<void, AddTracksToPlaylistParams> {
  const AddTracksToPlaylist(this._repo);

  final PlaylistRepository _repo;

  @override
  Future<void> call(AddTracksToPlaylistParams p) =>
      _repo.addTracks(p.trackIds, p.playlistId);
}

class RemoveTrackFromPlaylistParams {
  const RemoveTrackFromPlaylistParams(this.trackId, this.playlistId);

  final String trackId;
  final String playlistId;
}

/// 곡을 재생목록에서 빼기 (보관함에는 남는다).
class RemoveTrackFromPlaylist
    implements UseCase<void, RemoveTrackFromPlaylistParams> {
  const RemoveTrackFromPlaylist(this._repo);

  final PlaylistRepository _repo;

  @override
  Future<void> call(RemoveTrackFromPlaylistParams p) =>
      _repo.removeTrack(p.trackId, p.playlistId);
}

/// 재생목록 카드 순서 바꾸기: 좋아요 목록과 중복 · 빈 id는 빼고 저장한다 (좋아요 목록은 늘 맨 앞).
class ReorderPlaylists implements UseCase<void, List<String>> {
  const ReorderPlaylists(this._repo);

  final PlaylistRepository _repo;

  @override
  Future<void> call(List<String> playlistIds) => _repo.reorder([
    ...{
      for (final id in playlistIds)
        if (id.isNotEmpty && id != Playlist.favoritesId) id,
    },
  ]);
}
