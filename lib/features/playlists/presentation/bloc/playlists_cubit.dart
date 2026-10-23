import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/usecases/playlist_usecases.dart';

export '../../domain/entities/playlist.dart';

/// 재생목록 목록 (좋아요 목록이 맨 앞). 재생목록 탭 · 담기 선택 · 다운로드 팝업 등에서 쓴다.
class PlaylistsCubit extends Cubit<List<Playlist>> {
  PlaylistsCubit({
    required this._watch,
    required this._watchTracks,
    required this._create,
    required this._rename,
    required this._delete,
    required this._addTrack,
    required this._addTracks,
    required this._removeTrack,
    required this._reorder,
  }) : super(const []);

  final WatchPlaylists _watch;
  final WatchPlaylistTracks _watchTracks;
  final CreatePlaylist _create;
  final RenamePlaylist _rename;
  final DeletePlaylist _delete;
  final AddTrackToPlaylists _addTrack;
  final AddTracksToPlaylist _addTracks;
  final RemoveTrackFromPlaylist _removeTrack;
  final ReorderPlaylists _reorder;
  StreamSubscription<List<Playlist>>? _sub;

  void start() {
    _sub?.cancel();
    _sub = _watch(const NoParams()).listen(emit);
  }

  /// 재생목록에 담긴 곡 (담은 순서). 전체 재생에 쓴다.
  Future<List<Track>> tracksOf(String id) => _watchTracks(id).first;

  /// 새 재생목록. 이름이 비어 있으면 null.
  Future<Playlist?> create(String name) => _create(name);

  /// 이름 바꾸기. 비어 있으면 false.
  Future<bool> rename(String id, String name) =>
      _rename(RenamePlaylistParams(id, name));

  /// 재생목록 지우기 (곡은 보관함에 남는다).
  Future<bool> delete(String id) => _delete(id);

  /// 곡을 재생목록들에 담는다. 이미 들어 있는 곳은 건너뛴다.
  Future<void> addTrack(String trackId, Set<String> playlistIds) =>
      _addTrack(AddTrackToPlaylistsParams(trackId, playlistIds));

  /// 곡들을 재생목록 하나에 담는다. 이미 들어 있는 곡은 건너뛴다.
  Future<void> addTracks(Set<String> trackIds, String playlistId) =>
      _addTracks(AddTracksToPlaylistParams(trackIds, playlistId));

  /// 곡을 재생목록에서 뺀다 (보관함에는 남는다).
  Future<void> removeTrack(String trackId, String playlistId) =>
      _removeTrack(RemoveTrackFromPlaylistParams(trackId, playlistId));

  /// 재생목록 카드 순서를 [ids] 순서로 정한다 (좋아요 목록은 늘 맨 앞).
  Future<void> reorder(List<String> ids) => _reorder(ids);

  /// 좋아요한 곡인지.
  bool isFavorite(String trackId) =>
      state.any((p) => p.isFavorites && p.trackIds.contains(trackId));

  /// 좋아요를 켜고 끈다. 켰으면 true.
  Future<bool> toggleFavorite(String trackId) async {
    if (isFavorite(trackId)) {
      await _removeTrack(
        RemoveTrackFromPlaylistParams(trackId, Playlist.favoritesId),
      );
      return false;
    }
    await _addTrack(AddTrackToPlaylistsParams(trackId, {Playlist.favoritesId}));
    return true;
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
