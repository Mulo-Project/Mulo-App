import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_info.dart';
import '../../domain/usecases/library_usecases.dart';

class LibraryState extends Equatable {
  const LibraryState({
    this.tracks = const [],
    this.loaded = false,
    this.revision = 0,
  });

  /// 추가일 최신순.
  final List<Track> tracks;

  /// DB에서 처음 목록을 받았는지 (빈 보관함 안내를 깜빡이지 않게).
  final bool loaded;

  /// DB에서 새 목록을 받을 때마다 올라간다. 곡은 id만으로 같다고 보기 때문에,
  /// 곡 정보를 고쳐도 화면이 다시 그려지도록 목록 내용 대신 이 값을 비교한다.
  final int revision;

  @override
  List<Object?> get props => [tracks, loaded, revision];
}

/// 보관함 곡 목록. DB 변경을 구독한다.
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._watch, this._updateInfo, this._delete)
    : super(const LibraryState());

  final WatchLibraryTracks _watch;
  final UpdateTrackInfo _updateInfo;
  final DeleteTrack _delete;
  StreamSubscription<List<Track>>? _sub;

  void start() {
    _sub ??= _watch(const NoParams()).listen(
      (tracks) => emit(
        LibraryState(
          tracks: tracks,
          loaded: true,
          revision: state.revision + 1,
        ),
      ),
    );
  }

  /// 곡 정보 편집. 제목이 비어 있으면 바꾸지 않고 false.
  Future<bool> updateInfo(String trackId, TrackInfo info) =>
      _updateInfo(UpdateTrackInfoParams(trackId, info));

  Future<void> delete(String trackId) => _delete(trackId);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
