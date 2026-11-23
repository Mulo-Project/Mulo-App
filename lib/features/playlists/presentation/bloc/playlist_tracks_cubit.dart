import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../library/domain/entities/track.dart';
import '../../domain/usecases/playlist_usecases.dart';

/// 재생목록 하나에 담긴 곡 (상세 화면 · 담기 선택에서 이미 담긴 곡 표시).
class PlaylistTracksCubit extends Cubit<List<Track>?> {
  PlaylistTracksCubit(this._watch) : super(null);

  final WatchPlaylistTracks _watch;
  StreamSubscription<List<Track>>? _sub;

  /// 처음 받기 전에는 state가 null.
  void start(String playlistId) {
    _sub?.cancel();
    _sub = _watch(playlistId).listen(emit);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
