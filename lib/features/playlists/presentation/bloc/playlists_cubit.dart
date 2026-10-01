import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/usecases/playlist_usecases.dart';

/// 재생목록 목록. 다운로드 팝업의 재생목록 고르기 등에서 쓴다.
class PlaylistsCubit extends Cubit<List<Playlist>> {
  PlaylistsCubit(
    this._watch,
    this._create,
    this._setColor,
    this._addTrack,
    this._removeTrack,
  ) : super(const []);

  final WatchPlaylists _watch;
  final CreatePlaylist _create;
  final SetPlaylistColor _setColor;
  final AddTrackToPlaylists _addTrack;
  final RemoveTrackFromPlaylist _removeTrack;
  StreamSubscription<List<Playlist>>? _sub;

  void start() {
    _sub?.cancel();
    _sub = _watch(const NoParams()).listen(emit);
  }

  /// 새 재생목록. 이름이 비어 있으면 null.
  Future<Playlist?> create(String name) => _create(name);

  /// 이미지가 없는 카드의 색. [colorIndex]가 null이면 자동.
  Future<void> setColor(String id, int? colorIndex) =>
      _setColor(SetPlaylistColorParams(id, colorIndex));

  /// 곡을 재생목록들에 담는다. 이미 들어 있는 곳은 건너뛴다.
  Future<void> addTrack(String trackId, Set<String> playlistIds) =>
      _addTrack(AddTrackToPlaylistsParams(trackId, playlistIds));

  /// 곡을 재생목록에서 뺀다 (보관함에는 남는다).
  Future<void> removeTrack(String trackId, String playlistId) =>
      _removeTrack(RemoveTrackFromPlaylistParams(trackId, playlistId));

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
