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

class SetPlaylistColorParams {
  const SetPlaylistColorParams(this.playlistId, this.colorIndex);

  final String playlistId;
  final int? colorIndex;
}

/// 재생목록 카드 색 정하기 (null이면 자동).
class SetPlaylistColor implements UseCase<void, SetPlaylistColorParams> {
  const SetPlaylistColor(this._repo);

  final PlaylistRepository _repo;

  @override
  Future<void> call(SetPlaylistColorParams p) =>
      _repo.setColor(p.playlistId, p.colorIndex);
}
