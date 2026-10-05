import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/usecases/search_usecases.dart';

enum SearchStatus { idle, loading, loaded, failed }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.idle,
    this.items = const [],
    this.hasNext = false,
    this.loadingMore = false,
    this.playlistTitle,
    this.failure,
  });

  final SearchStatus status;

  /// 검색 결과, 또는 URL이 재생목록이면 그 항목들, 곡 하나면 한 개.
  final List<MediaHit> items;
  final bool hasNext;
  final bool loadingMore;

  /// URL이 재생목록일 때 그 이름. 아니면 null.
  final String? playlistTitle;
  final EngineFailure? failure;

  @override
  List<Object?> get props => [
    status,
    items,
    hasNext,
    loadingMore,
    playlistTitle,
    failure,
  ];
}

/// 검색 탭: 키워드 검색(쪽 이어 보기)과 URL 곡 정보 (상세 기능 #1 #2).
/// URL이면 정보를, 아니면 검색을 한다. 늦게 온 옛 요청의 답은 버린다.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._search, this._info) : super(const SearchState());

  final SearchTracks _search;
  final FetchMediaInfo _info;

  int _request = 0;
  String _query = '';
  SearchSource _source = SearchSource.youtube;
  int _page = 0;

  /// 입력이 곡 주소인지 (http · https 주소).
  static bool isUrl(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> submit(String text, SearchSource source) async {
    final query = text.trim();
    final id = ++_request;
    _query = query;
    _source = source;
    _page = 0;
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }
    emit(const SearchState(status: SearchStatus.loading));
    try {
      if (isUrl(query)) {
        final info = await _info(query);
        if (id != _request) return;
        emit(switch (info) {
          VideoInfo(:final hit) => SearchState(
            status: SearchStatus.loaded,
            items: [hit],
          ),
          PlaylistInfo(:final title, :final entries) => SearchState(
            status: SearchStatus.loaded,
            items: entries,
            playlistTitle: title,
          ),
        });
      } else {
        final page = await _search(SearchParams(query, source));
        if (id != _request) return;
        emit(
          SearchState(
            status: SearchStatus.loaded,
            items: page.items,
            hasNext: page.hasNext,
          ),
        );
      }
    } on EngineException catch (e) {
      if (id != _request) return;
      emit(SearchState(status: SearchStatus.failed, failure: e.failure));
    }
  }

  /// 결과 아래에서 다음 쪽을 이어 붙인다 (키워드 검색만).
  Future<void> loadMore() async {
    final s = state;
    if (s.status != SearchStatus.loaded || !s.hasNext || s.loadingMore) return;
    final id = _request;
    emit(
      SearchState(
        status: SearchStatus.loaded,
        items: s.items,
        hasNext: true,
        loadingMore: true,
      ),
    );
    try {
      final page = await _search(
        SearchParams(_query, _source, page: _page + 1),
      );
      if (id != _request) return;
      _page++;
      final known = {for (final h in s.items) h.id};
      emit(
        SearchState(
          status: SearchStatus.loaded,
          items: [...s.items, ...page.items.where((h) => known.add(h.id))],
          hasNext: page.hasNext,
        ),
      );
    } on EngineException {
      if (id != _request) return;
      // 이어 보기 실패는 이미 나온 결과를 두고 다시 누를 수 있게 한다.
      emit(
        SearchState(status: SearchStatus.loaded, items: s.items, hasNext: true),
      );
    }
  }
}
