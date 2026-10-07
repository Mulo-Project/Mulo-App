import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../account/domain/entities/google_account.dart';
import '../../../account/domain/usecases/account_usecases.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../downloads/domain/entities/download_request.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../search/domain/entities/engine_exception.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../../search/domain/usecases/search_usecases.dart';
import '../../domain/usecases/playlist_usecases.dart';

/// [results]는 키워드로 찾은 재생목록 목록을 보여 주는 상태.
enum PlaylistImportStatus { idle, loading, results, loaded, failed }

class PlaylistImportState extends Equatable {
  const PlaylistImportState({
    this.status = PlaylistImportStatus.idle,
    this.title = '',
    this.thumbnailUrl,
    this.entries = const [],
    this.selected = const {},
    this.failure,
    this.notPlaylist = false,
    this.results = const [],
    this.query = '',
    this.mine = false,
    this.accountFailure,
  });

  final PlaylistImportStatus status;

  /// 유튜브 재생목록 이름 (새 재생목록의 이름이 된다).
  final String title;

  /// 재생목록 대표 이미지 주소 (새 재생목록의 커버가 된다). 없으면 null.
  final String? thumbnailUrl;
  final List<MediaHit> entries;

  /// 고른 곡 id.
  final Set<String> selected;
  final EngineFailure? failure;

  /// 주소는 읽었지만 재생목록이 아니라 곡 하나였다.
  final bool notPlaylist;

  /// 키워드로 찾은 재생목록들. 하나를 골라 곡을 읽은 뒤에도 남겨 두어 돌아올 수 있다.
  final List<PlaylistHit> results;

  /// [results]를 찾은 검색어.
  final String query;

  /// [results]가 로그인한 계정의 재생목록인지 (검색 결과가 아니라).
  final bool mine;

  /// 내 재생목록을 읽다 실패한 까닭 (로그인이 풀렸는지 등).
  final AccountFailure? accountFailure;

  bool get allSelected =>
      entries.isNotEmpty && selected.length == entries.length;

  /// 고른 곡 (목록 순서대로).
  List<MediaHit> get selectedEntries => [
    for (final e in entries)
      if (selected.contains(e.id)) e,
  ];

  PlaylistImportState copyWith({Set<String>? selected}) => PlaylistImportState(
    status: status,
    title: title,
    thumbnailUrl: thumbnailUrl,
    entries: entries,
    selected: selected ?? this.selected,
    failure: failure,
    notPlaylist: notPlaylist,
    results: results,
    query: query,
    mine: mine,
  );

  @override
  List<Object?> get props => [
    status,
    title,
    thumbnailUrl,
    entries,
    selected,
    failure,
    notPlaylist,
    results,
    query,
    mine,
    accountFailure,
  ];
}

/// 새로 만든 재생목록과 받기를 시작한 곡 수.
class PlaylistImportResult extends Equatable {
  const PlaylistImportResult({
    required this.playlistId,
    required this.thumbnailUrl,
    required this.queued,
  });

  final String playlistId;
  final String? thumbnailUrl;
  final int queued;

  @override
  List<Object?> get props => [playlistId, thumbnailUrl, queued];
}

/// 유튜브 재생목록 가져오기 (상세 기능: 유튜브 재생목록 가져오기 #22):
/// 주소로 곡 목록을 읽고, 고른 곡을 같은 이름의 새 재생목록으로 받는다.
/// 늦게 온 옛 요청의 답은 버린다.
class PlaylistImportCubit extends Cubit<PlaylistImportState> {
  PlaylistImportCubit(
    this._info,
    this._search,
    this._mine,
    this._enqueue,
    this._create,
  ) : super(const PlaylistImportState());

  final FetchMediaInfo _info;
  final SearchPlaylists _search;
  final FetchMyPlaylists _mine;
  final EnqueueDownload _enqueue;
  final CreatePlaylist _create;

  int _request = 0;

  /// 입력이 재생목록 주소면 곡 목록을 읽고, 아니면 키워드로 재생목록을 찾는다.
  Future<void> submit(String input) {
    final text = input.trim();
    return _looksLikeUrl(text) ? load(text) : search(text);
  }

  static bool _looksLikeUrl(String text) =>
      text.startsWith('http://') ||
      text.startsWith('https://') ||
      text.contains('youtube.com/') ||
      text.contains('youtu.be/');

  /// 키워드로 유튜브 재생목록을 찾아 목록으로 보여 준다.
  Future<void> search(String query) async {
    final id = ++_request;
    final q = query.trim();
    if (q.isEmpty) {
      emit(const PlaylistImportState());
      return;
    }
    emit(PlaylistImportState(status: PlaylistImportStatus.loading, query: q));
    try {
      final page = await _search(PlaylistSearchParams(q));
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.results,
          results: page.items,
          query: q,
        ),
      );
    } on EngineException catch (e) {
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.failed,
          failure: e.failure,
          query: q,
        ),
      );
    }
  }

  /// 로그인한 계정의 유튜브 재생목록을 불러와 목록으로 보여 준다 (로그인은 미리 돼 있어야 한다).
  Future<void> loadMine() async {
    final id = ++_request;
    emit(const PlaylistImportState(status: PlaylistImportStatus.loading));
    try {
      final items = await _mine(const NoParams());
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.results,
          results: items,
          mine: true,
        ),
      );
    } on AccountException catch (e) {
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.failed,
          accountFailure: e.failure,
          mine: true,
        ),
      );
    }
  }

  /// 찾은 재생목록 하나를 골라 곡 목록을 읽는다.
  Future<void> open(PlaylistHit hit) => load(hit.url);

  /// 곡 목록에서 찾은 재생목록 목록으로 돌아간다.
  void backToResults() {
    _request++;
    emit(
      PlaylistImportState(
        status: PlaylistImportStatus.results,
        results: state.results,
        query: state.query,
        mine: state.mine,
      ),
    );
  }

  /// 주소의 재생목록을 읽는다. 처음에는 곡을 모두 고른 채로 둔다.
  Future<void> load(String url) async {
    final id = ++_request;
    if (url.trim().isEmpty) {
      emit(const PlaylistImportState());
      return;
    }
    final keep = state.results;
    final keepQuery = state.query;
    final keepMine = state.mine;
    emit(
      PlaylistImportState(
        status: PlaylistImportStatus.loading,
        results: keep,
        query: keepQuery,
        mine: keepMine,
      ),
    );
    try {
      final info = await _info(url);
      if (id != _request) return;
      switch (info) {
        case PlaylistInfo(:final title, :final entries, :final thumbnailUrl):
          final usable = [
            for (final e in entries)
              if (e.url.isNotEmpty) e,
          ];
          emit(
            PlaylistImportState(
              status: PlaylistImportStatus.loaded,
              title: title,
              // 대표 이미지를 모르면 첫 곡의 이미지를 쓴다.
              thumbnailUrl:
                  thumbnailUrl ??
                  usable.map((e) => e.thumbnailUrl).nonNulls.firstOrNull,
              entries: usable,
              selected: {for (final e in usable) e.id},
              results: keep,
              query: keepQuery,
              mine: keepMine,
            ),
          );
        case VideoInfo():
          emit(
            PlaylistImportState(
              status: PlaylistImportStatus.failed,
              notPlaylist: true,
              results: keep,
              query: keepQuery,
              mine: keepMine,
            ),
          );
      }
    } on EngineException catch (e) {
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.failed,
          failure: e.failure,
          results: keep,
          query: keepQuery,
          mine: keepMine,
        ),
      );
    }
  }

  void toggle(String trackId) {
    final next = {...state.selected};
    next.contains(trackId) ? next.remove(trackId) : next.add(trackId);
    emit(state.copyWith(selected: next));
  }

  /// 모두 골랐으면 모두 해제하고, 아니면 모두 고른다.
  void toggleAll() => emit(
    state.copyWith(
      selected: state.allSelected ? {} : {for (final e in state.entries) e.id},
    ),
  );

  /// 고른 곡을 받기 대기열에 넣고 재생목록을 만든다. 고른 곡이 없으면 null.
  /// 받는 곡은 받기가 끝나면 이 재생목록에 담긴다.
  Future<PlaylistImportResult?> start() async {
    final picked = state.selectedEntries;
    if (picked.isEmpty) return null;
    final made = await _create(state.title.isEmpty ? '?' : state.title);
    if (made == null) return null;
    var queued = 0;
    for (final hit in picked) {
      final ok = await _enqueue(
        DownloadRequest(
          title: hit.title,
          artist: hit.uploader,
          playlistIds: {made.id},
          duration: hit.duration,
          thumbnailUrl: hit.thumbnailUrl,
          url: hit.url,
        ),
      );
      if (ok) queued++;
    }
    return PlaylistImportResult(
      playlistId: made.id,
      thumbnailUrl: state.thumbnailUrl,
      queued: queued,
    );
  }
}
