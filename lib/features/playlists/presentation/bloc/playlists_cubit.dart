import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/usecases/playlist_usecases.dart';

/// 재생목록 목록. 다운로드 팝업의 재생목록 고르기 등에서 쓴다.
class PlaylistsCubit extends Cubit<List<Playlist>> {
  PlaylistsCubit(this._watch, this._create, this._setColor) : super(const []);

  final WatchPlaylists _watch;
  final CreatePlaylist _create;
  final SetPlaylistColor _setColor;
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

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
