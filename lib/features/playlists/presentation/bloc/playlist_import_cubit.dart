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
    this.channel = '',
    this.accountFailure,
    this.accountDetail = '',
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

  /// [results]가 이 채널의 재생목록이면 채널 이름 (아니면 빈 문자열).
  final String channel;

  /// 구글 계정으로 읽는 목록(내 재생목록 · 채널 재생목록)이었는지.
  bool get fromAccount => mine || channel.isNotEmpty || accountFailure != null;

  /// 내 재생목록을 읽다 실패한 까닭 (로그인이 풀렸는지 등).
  final AccountFailure? accountFailure;

  /// 내 재생목록 읽기 실패의 자세한 까닭 (구글 응답 · 예외, 진단용).
  final String accountDetail;

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
    channel: channel,
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
    channel,
    accountFailure,
    accountDetail,
  ];
}

/// 새로 만든 재생목록과 받기를 시작한 곡 수.
class PlaylistImportResult extends Equatable {
  const PlaylistImportResult({
    required this.playlistId,
    required this.thumbnailUrl,
    required this.queued,
    this.skipped = 0,
  });

  final String playlistId;
  final String? thumbnailUrl;
  final int queued;

  /// 이미 받았거나 받는 중이라 다시 받지 않은 곡 수 (이미 받은 곡은 새 재생목록에는 담긴다).
  final int skipped;

  @override
  List<Object?> get props => [playlistId, thumbnailUrl, queued, skipped];
}

/// 유튜브 재생목록 가져오기 (상세 기능: 유튜브 재생목록 가져오기 #22):
/// 주소로 곡 목록을 읽고, 고른 곡을 같은 이름의 새 재생목록으로 받는다.
/// 이미 받은 곡은 다시 받지 않고 새 재생목록에만 담는다. 늦게 온 옛 요청의 답은 버린다.
class PlaylistImportCubit extends Cubit<PlaylistImportState> {
  PlaylistImportCubit(
    this._info,
    this._search,
    this._mine,
    this._enqueue,
    this._create,
    this._findExisting,
    this._addTracks,
    this._channelPlaylists,
  ) : super(const PlaylistImportState());

  final FetchMediaInfo _info;
  final SearchPlaylists _search;
  final FetchMyPlaylists _mine;
  final EnqueueDownload _enqueue;
  final CreatePlaylist _create;
  final FindExistingDownload _findExisting;
  final AddTracksToPlaylist _addTracks;
  final FetchChannelPlaylists _channelPlaylists;

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
          accountDetail: e.message,
          mine: true,
        ),
      );
    } on Object catch (e) {
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.failed,
          accountFailure: AccountFailure.failed,
          accountDetail: '$e',
          mine: true,
        ),
      );
    }
  }

  /// 구독한 채널 [channelId]의 재생목록들을 목록으로 보여 준다 (구글 로그인이 돼 있어야 한다).
  /// 맨 위에 그 채널의 업로드 전체([uploadsTitle])를 하나 더 둔다. 업로드 목록의 id는 채널 id의 `UC`를 `UU`로 바꾼 것이다.
  Future<void> loadChannel(
    String channelId,
    String channelName,
    String uploadsTitle,
  ) async {
    final id = ++_request;
    emit(const PlaylistImportState(status: PlaylistImportStatus.loading));
    try {
      final items = await _channelPlaylists(channelId);
      if (id != _request) return;
      final uploadsId = channelId.startsWith('UC')
          ? 'UU${channelId.substring(2)}'
          : null;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.results,
          results: [
            if (uploadsId != null)
              PlaylistHit(
                id: uploadsId,
                title: uploadsTitle,
                url: 'https://www.youtube.com/playlist?list=$uploadsId',
                channel: channelName,
              ),
            for (final h in items)
              if (h.id != uploadsId) h,
          ],
          channel: channelName,
        ),
      );
    } on AccountException catch (e) {
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.failed,
          accountFailure: e.failure,
          accountDetail: e.message,
          channel: channelName,
        ),
      );
    } on Object catch (e) {
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.failed,
          accountFailure: AccountFailure.failed,
          accountDetail: '$e',
          channel: channelName,
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
        channel: state.channel,
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
    final keepChannel = state.channel;
    emit(
      PlaylistImportState(
        status: PlaylistImportStatus.loading,
        results: keep,
        query: keepQuery,
        mine: keepMine,
        channel: keepChannel,
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
              channel: keepChannel,
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
              channel: keepChannel,
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
          channel: keepChannel,
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
    var skipped = 0;
    final already = <String>{};
    for (final hit in picked) {
      // 이미 받은 곡은 다시 받지 않는다 (재생목록은 다시 가져와도 같은 곡이 쌓이지 않도록).
      final existing = await _findExisting(hit.url);
      if (existing.exists) {
        skipped++;
        if (existing.trackId case final id?) already.add(id);
        continue;
      }
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
    if (already.isNotEmpty) {
      await _addTracks(AddTracksToPlaylistParams(already, made.id));
    }
    return PlaylistImportResult(
      playlistId: made.id,
      thumbnailUrl: state.thumbnailUrl,
      queued: queued,
      skipped: skipped,
    );
  }
}
