import 'dart:async';

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
    this.category,
    this.probing = false,
  });

  final SearchStatus status;

  /// 검색 결과, 또는 URL이 재생목록이면 그 항목들, 곡 하나면 한 개.
  final List<MediaHit> items;
  final bool hasNext;
  final bool loadingMore;

  /// URL이 재생목록일 때 그 이름. 아니면 null.
  final String? playlistTitle;
  final EngineFailure? failure;

  /// 고른 분류 필터. null이면 전체.
  final String? category;

  /// 곡마다 분류를 읽는 중인지 (읽은 곡부터 필터에 걸린다).
  final bool probing;

  /// 분류 필터를 적용한 목록.
  List<MediaHit> get visibleItems => category == null
      ? items
      : [
          for (final h in items)
            if (h.categories.contains(category)) h,
        ];

  SearchState copyWith({
    List<MediaHit>? items,
    bool? hasNext,
    bool? loadingMore,
    String? Function()? category,
    bool? probing,
  }) => SearchState(
    status: status,
    items: items ?? this.items,
    hasNext: hasNext ?? this.hasNext,
    loadingMore: loadingMore ?? this.loadingMore,
    playlistTitle: playlistTitle,
    failure: failure,
    category: category == null ? this.category : category(),
    probing: probing ?? this.probing,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    hasNext,
    loadingMore,
    playlistTitle,
    failure,
    category,
    probing,
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

  /// 분류를 알아보려고 이미 불러 본 곡 주소 (실패해도 다시 하지 않는다).
  final _probed = <String>{};

  /// 분류를 한 번에 알아보는 곡 수.
  static const _probeParallel = 6;

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
    _probed.clear();
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
        if (info is PlaylistInfo) unawaited(_probeCategories(id));
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
        unawaited(_probeCategories(id));
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
    emit(s.copyWith(hasNext: true, loadingMore: true));
    try {
      final page = await _search(
        SearchParams(_query, _source, page: _page + 1),
      );
      if (id != _request) return;
      _page++;
      final known = {for (final h in s.items) h.id};
      emit(
        s.copyWith(
          items: [...s.items, ...page.items.where((h) => known.add(h.id))],
          hasNext: page.hasNext,
          loadingMore: false,
        ),
      );
      unawaited(_probeCategories(id));
    } on EngineException {
      if (id != _request) return;
      // 이어 보기 실패는 이미 나온 결과를 두고 다시 누를 수 있게 한다.
      emit(s.copyWith(hasNext: true, loadingMore: false));
    }
  }

  /// 분류 필터를 고른다 (null이면 전체). 이미 고른 것을 다시 누르면 푼다.
  void selectCategory(String? category) {
    final now = state.category == category ? null : category;
    emit(state.copyWith(category: () => now));
  }

  /// 목록 항목은 분류가 비어 있어서, 곡마다 정보를 읽어 분류를 채운다.
  /// 몇 곡씩 뒤에서 읽고, 읽은 곡부터 분류 필터에 걸린다.
  Future<void> _probeCategories(int request) async {
    emit(state.copyWith(probing: true));
    Future<void> worker() async {
      while (request == _request && !isClosed) {
        final next = state.items
            .where((h) => h.categories.isEmpty && !_probed.contains(h.url))
            .firstOrNull;
        if (next == null) return;
        _probed.add(next.url);
        try {
          final info = await _info(next.url);
          if (request != _request || isClosed) return;
          final cats = switch (info) {
            VideoInfo(:final hit) => hit.categories,
            PlaylistInfo() => const <String>[],
          };
          if (cats.isEmpty) continue;
          emit(
            state.copyWith(
              items: [
                for (final h in state.items)
                  h.url == next.url ? h.withCategories(cats) : h,
              ],
            ),
          );
        } on EngineException {
          // 분류를 못 읽은 곡은 그냥 필터에 안 걸린다.
        }
      }
    }

    await Future.wait([for (var i = 0; i < _probeParallel; i++) worker()]);
    if (request == _request && !isClosed) {
      emit(state.copyWith(probing: false));
    }
  }
}
