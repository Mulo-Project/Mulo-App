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
  MediaDetailCubit(
    MediaHit hit,
    this._fetch,
    this._fetchChannel,
    this._openLink,
  ) : super(MediaDetailState(hit: hit));

  final FetchMediaInfo _fetch;
  final FetchChannelInfo _fetchChannel;
  final OpenLink _openLink;

  /// 곡 정보와 채널 정보를 따로 동시에 읽고, 읽히는 대로 화면에 채운다.
  /// 채널 주소를 이미 알면(검색 목록에 있다) 곡 정보를 기다리지 않고 바로 읽는다.
  Future<void> load() async {
    emit(MediaDetailState(hit: state.hit, loading: true));
    final early = _needsChannel(state.hit) ? _loadChannel() : null;
    await _loadInfo();
    // 곡 정보에서 비로소 채널 주소를 알게 된 경우.
    await (early ?? (_needsChannel(state.hit) ? _loadChannel() : null));
  }

  /// 채널 주소는 아는데 이미지 · 구독자 수가 비어 있는지.
  static bool _needsChannel(MediaHit hit) =>
      hit.channelUrl != null &&
      (hit.channelThumbnailUrl == null || hit.subscriberCount == null);

  Future<void> _loadInfo() async {
    try {
      final info = await _fetch(state.hit.url);
      if (isClosed) return;
      emit(
        MediaDetailState(
          hit: switch (info) {
            VideoInfo(hit: final full) => state.hit.filledFrom(full),
            PlaylistInfo() => state.hit,
          },
        ),
      );
    } on EngineException {
      if (isClosed) return;
      emit(MediaDetailState(hit: state.hit));
    }
  }

  /// 채널 이미지 · 구독자 수는 곡 정보에 없을 수 있어 따로 읽는다 (못 읽으면 그대로 둔다).
  Future<void> _loadChannel() async {
    try {
      final channel = await _fetchChannel(state.hit.channelUrl!);
      if (isClosed) return;
      emit(
        MediaDetailState(
          hit: state.hit.withChannel(channel),
          loading: state.loading,
        ),
      );
    } on EngineException {
      // 채널 정보가 없어도 상세 보기는 그대로 쓸 수 있다.
    }
  }

  /// 영상 · 채널 주소를 연다. 못 열었으면 false.
  Future<bool> open(String url) => _openLink(url);
}
