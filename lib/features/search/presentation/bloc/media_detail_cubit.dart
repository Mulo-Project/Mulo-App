import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/usecases/search_usecases.dart';
import 'media_hit_memo.dart';

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
    this._openLink, {
    MediaHitMemo? memo,
    this.stored = false,
    FetchFullMediaInfo? fetchFull,
  }) : _memo = memo,
       _fetchFull = fetchFull,
       _known = memo?.get(hit.url),
       super(MediaDetailState(hit: memo?.get(hit.url) ?? hit));

  /// 앱에 저장해 둔 곡 정보다: 조회수 · 올린 날이 없는 곡(SoundCloud 등)이어도 다시 읽지 않는다.
  final bool stored;

  /// 자세히 읽은 곡 정보를 기억해 두는 곳 (없으면 매번 읽는다).
  final MediaHitMemo? _memo;

  /// 이 곡을 전에 자세히 읽어 기억해 둔 게 있다 (그러면 다시 읽지 않는다).
  final MediaHit? _known;
  var _infoLoaded = false;

  final FetchMediaInfo _fetch;

  /// 빠른 곡 정보 뒤에 좋아요 수 · 공동 작업자 같은 느리게 읽히는 정보를 채우는 읽기 (없으면 채우지 않는다).
  final FetchFullMediaInfo? _fetchFull;
  final FetchChannelInfo _fetchChannel;
  final OpenLink _openLink;

  /// 곡 정보와 채널 정보를 따로 동시에 읽고, 읽히는 대로 화면에 채운다.
  /// 채널 주소를 이미 알면(검색 목록에 있다) 곡 정보를 기다리지 않고 바로 읽는다.
  Future<void> load() async {
    // 전에 읽은 것이 있으면 처음부터 채워 보여 주고, 다시 읽지 않는다.
    if (_known != null) return;
    // 저장한 곡처럼 상세 정보가 이미 들어 있으면 로딩 없이 그대로 보여 준다 (채널 이미지만 비었으면 조용히 채운다).
    if (stored || _hasStoredDetail(state.hit)) {
      if (_needsChannel(state.hit)) await _loadChannel();
      return;
    }
    emit(MediaDetailState(hit: state.hit, loading: true));
    final early = _needsChannel(state.hit) ? _loadChannel() : null;
    await _loadInfo();
    // 곡 정보에서 비로소 채널 주소를 알게 된 경우.
    await (early ?? (_needsChannel(state.hit) ? _loadChannel() : null));
    // 곡 정보를 잘 읽었으면 다음에 다시 열 때를 위해 기억한다 (느린 나머지를 채울 거면 그 뒤에).
    if (_infoLoaded && !isClosed && _fetchFull == null) {
      _memo?.put(state.hit.url, state.hit);
    }
    // 느리게 읽히는 나머지(좋아요 수 · 공동 작업자 · 앨범)는 화면을 띄운 뒤 뒤에서 채운다.
    if (_infoLoaded) await _loadFull();
  }

  Future<void> _loadFull() async {
    final fetch = _fetchFull;
    if (fetch == null) return;
    try {
      final info = await fetch(state.hit.url);
      if (isClosed) return;
      if (info is VideoInfo) {
        emit(
          MediaDetailState(
            hit: state.hit.filledFrom(info.hit),
            loading: state.loading,
          ),
        );
      }
    } on EngineException {
      // 못 읽어도 빠르게 읽은 정보로 충분히 쓸 수 있다.
    }
    if (!isClosed) _memo?.put(state.hit.url, state.hit);
  }

  /// 앱에 저장해 둔 상세 정보(조회수 · 올린 날 · 채널)가 이미 있는지. 검색 목록 항목에는 없다.
  static bool _hasStoredDetail(MediaHit hit) =>
      hit.viewCount != null && hit.uploadedAt != null && hit.channelUrl != null;

  /// 채널 주소는 아는데 이미지 · 구독자 수가 비어 있는지.
  static bool _needsChannel(MediaHit hit) =>
      hit.channelUrl != null &&
      (hit.channelThumbnailUrl == null || hit.subscriberCount == null);

  Future<void> _loadInfo() async {
    try {
      final info = await _fetch(state.hit.url);
      if (isClosed) return;
      _infoLoaded = info is VideoInfo;
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
