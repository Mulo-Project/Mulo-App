import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/usecases/search_usecases.dart';

class MediaDetailState extends Equatable {
  const MediaDetailState({required this.hit, this.loading = false});

  /// 지금까지 알아낸 곡 정보. 자세히 읽는 동안에도 목록에서 알던 만큼은 보인다.
  final MediaHit hit;

  /// 채널 · 조회수 같은 나머지 정보를 읽는 중인지.
  final bool loading;

  @override
  List<Object?> get props => [hit, loading];
}

/// 검색 결과 하나의 상세 보기. 목록 항목에 없는 정보(채널 주소 · 조회수 · 올린 날 · 설명)를
/// 곡 정보를 한 번 더 읽어 채운다. 못 읽으면 알던 정보만 그대로 보여 준다.
class MediaDetailCubit extends Cubit<MediaDetailState> {
  MediaDetailCubit(MediaHit hit, this._fetch, this._openLink)
    : super(MediaDetailState(hit: hit));

  final FetchMediaInfo _fetch;
  final OpenLink _openLink;

  Future<void> load() async {
    final hit = state.hit;
    emit(MediaDetailState(hit: hit, loading: true));
    try {
      final info = await _fetch(hit.url);
      if (isClosed) return;
      emit(
        MediaDetailState(
          hit: switch (info) {
            VideoInfo(hit: final full) => hit.filledFrom(full),
            PlaylistInfo() => hit,
          },
        ),
      );
    } on EngineException {
      if (isClosed) return;
      emit(MediaDetailState(hit: hit));
    }
  }

  /// 영상 · 채널 주소를 연다. 못 열었으면 false.
  Future<bool> open(String url) => _openLink(url);
}
