import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_group.dart';
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

  /// 곡 정보 편집 (파일 태그에 먼저 쓰고 DB에 저장). 제목이 비었거나 태그 쓰기가 실패하면 바꾸지 않는다.
  Future<UpdateInfoResult> updateInfo(String trackId, TrackInfo info) =>
      _updateInfo(UpdateTrackInfoParams(trackId, info));

  /// 아티스트 · 앨범 · 장르의 이름을 바꾼다: [kind] 묶음 [from]에 속한 모든 곡의 그 정보를 [to]로 고친다.
  /// 이미 있는 이름이면 그 묶음과 합쳐진다. 곡마다 순서대로 (파일 태그 → 기록) 고치므로 한 곡이 끝날 때마다
  /// [onProgress]로 (끝낸 수, 전체 수)를 알린다. 바뀐 곡 수와, 태그 쓰기 실패로 못 바꾼 곡 수를 돌려준다.
  Future<({int changed, int failed})> renameGroup(
    TrackGroupKind kind,
    String from,
    String to, {
    void Function(int done, int total)? onProgress,
  }) async {
    final name = to.trim();
    if (name == from) return (changed: 0, failed: 0);
    return _renameAll(
      state.tracks.where((t) => kind.contains(t, from)).toList(),
      kind,
      name,
      onProgress,
    );
  }

  /// 고른 곡들([ids])의 [kind] 정보(아티스트 · 앨범 · 장르)를 모두 [to]로 지정한다. 제목은 건드리지 않는다.
  /// 곡마다 순서대로 (파일 태그 → 기록) 고치고, 한 곡이 끝날 때마다 [onProgress]로 (끝낸 수, 전체 수)를 알린다.
  Future<({int changed, int failed})> assignGroup(
    Set<String> ids,
    TrackGroupKind kind,
    String to, {
    void Function(int done, int total)? onProgress,
  }) => _renameAll(
    state.tracks.where((t) => ids.contains(t.id)).toList(),
    kind,
    to.trim(),
    onProgress,
  );

  Future<({int changed, int failed})> _renameAll(
    List<Track> tracks,
    TrackGroupKind kind,
    String name,
    void Function(int done, int total)? onProgress,
  ) async {
    var changed = 0;
    var failed = 0;
    onProgress?.call(0, tracks.length);
    for (final (i, t) in tracks.indexed) {
      final result = await updateInfo(t.id, kind.rename(t, name));
      if (result == UpdateInfoResult.saved) changed++;
      if (result == UpdateInfoResult.tagWriteFailed) failed++;
      onProgress?.call(i + 1, tracks.length);
    }
    return (changed: changed, failed: failed);
  }

  /// 음악 파일과 보관함 기록을 지운다. 파일을 못 지우면 false (기록은 그대로).
  Future<bool> delete(Track track) => _delete(track);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
