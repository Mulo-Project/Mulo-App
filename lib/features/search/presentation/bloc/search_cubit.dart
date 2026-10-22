import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_sort.dart';
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
    this.keyword = false,
    this.sort = SearchSort.relevance,
  });

  final SearchStatus status;

  /// 검색 결과, 또는 URL이 재생목록이면 그 항목들, 곡 하나면 한 개.
  final List<MediaHit> items;
  final bool hasNext;
  final bool loadingMore;

  /// URL이 재생목록일 때 그 이름. 아니면 null.
  final String? playlistTitle;
  final EngineFailure? failure;

  /// 키워드 검색 결과인지 (URL로 불러온 곡 · 재생목록이 아니라). 최신순은 검색을
  /// 다시 해야 해서 키워드 검색일 때만 쓸 수 있다.
  final bool keyword;

  /// 고른 정렬 순서.
  final SearchSort sort;

  /// 정렬을 적용한 목록. 최신순은 엔진이 날짜 순으로 찾아 준 그대로다.
  List<MediaHit> get visibleItems {
    final shown = [...items];
    // 길이를 모르는 곡은 어느 쪽 정렬이든 맨 뒤로 보낸다.
    int byDuration(MediaHit a, MediaHit b, int sign) {
      final x = a.duration, y = b.duration;
      if (x == null || y == null) {
        return x == null && y == null ? 0 : (x == null ? 1 : -1);
      }
      return sign * x.compareTo(y);
    }

    // 조회수를 모르는 곡은 맨 뒤로 보낸다.
    int byViews(MediaHit a, MediaHit b) {
      final x = a.viewCount, y = b.viewCount;
      if (x == null || y == null) {
        return x == null && y == null ? 0 : (x == null ? 1 : -1);
      }
      return y.compareTo(x);
    }

    switch (sort) {
      case SearchSort.relevance || SearchSort.newest:
        break;
      case SearchSort.popular:
        shown.sort(byViews);
      case SearchSort.shortest:
        shown.sort((a, b) => byDuration(a, b, 1));
      case SearchSort.longest:
        shown.sort((a, b) => byDuration(a, b, -1));
      case SearchSort.title:
        shown.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return shown;
  }

  SearchState copyWith({
    List<MediaHit>? items,
    bool? hasNext,
    bool? loadingMore,
    SearchSort? sort,
  }) => SearchState(
    status: status,
    items: items ?? this.items,
    hasNext: hasNext ?? this.hasNext,
    loadingMore: loadingMore ?? this.loadingMore,
    playlistTitle: playlistTitle,
    failure: failure,
    keyword: keyword,
    sort: sort ?? this.sort,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    hasNext,
    loadingMore,
    playlistTitle,
    failure,
    keyword,
    sort,
  ];
}

/// 검색 탭: 키워드 검색(쪽 이어 보기)과 URL 곡 정보 (상세 기능 #1 #2).
/// URL이면 정보를, 아니면 검색을 한다. 늦게 온 옛 요청의 답은 버린다.
///
/// 곡마다 상세 정보를 뒤에서 읽지 않는다 (느려진다). 목록에 있는 정보만으로
/// 정렬하고, 상세는 곡을 열 때 읽는다.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._search, this._info) : super(const SearchState());

  final SearchTracks _search;
  final FetchMediaInfo _info;

  int _request = 0;
  String _query = '';

  /// 마지막으로 찾은 입력 (재생목록 주소를 가져오기 화면으로 넘길 때 쓴다).
  String get query => _query;
  SearchSource _source = SearchSource.youtube;

  /// 마지막으로 찾은 사이트.
  SearchSource get source => _source;
  int _page = 0;

  /// 지금 결과를 최신순(날짜 순 검색)으로 찾아 왔는지. 고른 정렬이 최신순에서
  /// 다른 정렬로 바뀌어도 찾아 온 순서는 그대로라, 따로 기억한다.
  bool _newestFetched = false;

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
    _newestFetched = false;
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
        await _searchKeyword(id, SearchSort.relevance);
      }
    } on EngineException catch (e) {
      if (id != _request) return;
      emit(SearchState(status: SearchStatus.failed, failure: e.failure));
    }
  }

  /// 키워드로 첫 쪽을 찾아 담는다. [sort]를 그대로 고른 정렬로 둔다.
  Future<void> _searchKeyword(int id, SearchSort sort) async {
    final newest = sort == SearchSort.newest;
    final page = await _search(SearchParams(_query, _source, newest: newest));
    if (id != _request) return;
    _newestFetched = newest;
    emit(
      SearchState(
        status: SearchStatus.loaded,
        items: page.items,
        hasNext: page.hasNext,
        keyword: true,
        sort: sort,
      ),
    );
  }

  /// 결과 아래에서 다음 쪽을 이어 붙인다 (키워드 검색만).
  Future<void> loadMore() async {
    final s = state;
    if (s.status != SearchStatus.loaded || !s.hasNext || s.loadingMore) return;
    final id = _request;
    emit(s.copyWith(hasNext: true, loadingMore: true));
    try {
      final page = await _search(
        SearchParams(_query, _source, page: _page + 1, newest: _newestFetched),
      );
      if (id != _request) return;
      _page++;
      // 기다리는 사이에 정렬을 바꿨을 수 있어, 시작할 때 본 상태가 아니라 지금 상태에 이어 붙인다.
      final now = state;
      final known = {for (final h in now.items) h.id};
      emit(
        now.copyWith(
          items: [...now.items, ...page.items.where((h) => known.add(h.id))],
          hasNext: page.hasNext,
          loadingMore: false,
        ),
      );
    } on EngineException {
      if (id != _request) return;
      // 이어 보기 실패는 이미 나온 결과를 두고 다시 누를 수 있게 한다.
      emit(state.copyWith(hasNext: true, loadingMore: false));
    }
  }

  /// 정렬 순서를 고른다. 최신순을 고르거나, 최신순으로 찾은 결과에서 관련도순으로
  /// 돌아올 때는 찾는 순서가 달라지므로 첫 쪽부터 다시 찾는다.
  /// 그 밖에는 받아 온 결과 안에서만 바꾼다.
  Future<void> selectSort(SearchSort sort) async {
    final s = state;
    if (s.sort == sort) return;
    final reload =
        s.keyword &&
        s.status == SearchStatus.loaded &&
        ((sort == SearchSort.newest && !_newestFetched) ||
            (sort == SearchSort.relevance && _newestFetched));
    if (!reload) {
      emit(s.copyWith(sort: sort));
      return;
    }
    final id = ++_request;
    _page = 0;
    emit(SearchState(status: SearchStatus.loading, keyword: true, sort: sort));
    try {
      await _searchKeyword(id, sort);
    } on EngineException catch (e) {
      if (id != _request) return;
      emit(SearchState(status: SearchStatus.failed, failure: e.failure));
    }
  }
}
