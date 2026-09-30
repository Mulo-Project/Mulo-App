import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/usecases/playlist_usecases.dart';

/// 재생목록 목록. 다운로드 팝업의 재생목록 고르기 등에서 쓴다.
class PlaylistsCubit extends Cubit<List<Playlist>> {
  PlaylistsCubit(this._watch, this._create) : super(const []);

  final WatchPlaylists _watch;
  final CreatePlaylist _create;
  StreamSubscription<List<Playlist>>? _sub;

  void start() {
    _sub?.cancel();
    _sub = _watch(const NoParams()).listen(emit);
  }

  /// 새 재생목록. 이름이 비어 있으면 null.
  Future<Playlist?> create(String name) => _create(name);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
