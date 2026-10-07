import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../downloads/domain/entities/download_request.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../search/domain/entities/engine_exception.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../../search/domain/usecases/search_usecases.dart';
import '../../domain/usecases/playlist_usecases.dart';

enum PlaylistImportStatus { idle, loading, loaded, failed }

class PlaylistImportState extends Equatable {
  const PlaylistImportState({
    this.status = PlaylistImportStatus.idle,
    this.title = '',
    this.thumbnailUrl,
    this.entries = const [],
    this.selected = const {},
    this.failure,
    this.notPlaylist = false,
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
    this._enqueue,
    this._create,
    this._findExisting,
    this._addTracks,
  ) : super(const PlaylistImportState());

  final FetchMediaInfo _info;
  final EnqueueDownload _enqueue;
  final CreatePlaylist _create;
  final FindExistingDownload _findExisting;
  final AddTracksToPlaylist _addTracks;

  int _request = 0;

  /// 주소의 재생목록을 읽는다. 처음에는 곡을 모두 고른 채로 둔다.
  Future<void> load(String url) async {
    final id = ++_request;
    if (url.trim().isEmpty) {
      emit(const PlaylistImportState());
      return;
    }
    emit(const PlaylistImportState(status: PlaylistImportStatus.loading));
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
            ),
          );
        case VideoInfo():
          emit(
            const PlaylistImportState(
              status: PlaylistImportStatus.failed,
              notPlaylist: true,
            ),
          );
      }
    } on EngineException catch (e) {
      if (id != _request) return;
      emit(
        PlaylistImportState(
          status: PlaylistImportStatus.failed,
          failure: e.failure,
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
