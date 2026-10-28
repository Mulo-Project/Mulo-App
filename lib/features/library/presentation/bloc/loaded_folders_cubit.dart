import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/loaded_folder.dart';
import '../../domain/usecases/library_usecases.dart';
import '../../domain/usecases/loaded_folder_usecases.dart';

/// 폴더를 바꾼 뒤 보관함을 다시 채우는 단계 (빼는 중은 [removing]).
enum LoadStage { none, scanning, reading, covers, removing }

class LoadedFoldersState extends Equatable {
  const LoadedFoldersState({
    this.folders = const [],
    this.stage = LoadStage.none,
    this.done = 0,
    this.total = 0,
    this.coversSeq = 0,
  });

  /// 기본 저장 위치가 맨 위.
  final List<LoadedFolder> folders;

  /// 폴더를 바꾸고 보관함을 다시 채우는 중이면 지금 단계.
  final LoadStage stage;

  /// 단계 안의 진행 (끝낸 곡 수 / 전체). 전체를 모르면 0.
  final int done;
  final int total;

  /// 내장 커버를 새로 붙이거나 태그를 되살릴 때마다 오른다 (화면이 커버 목록을 다시 읽는다).
  final int coversSeq;

  bool get busy => stage != LoadStage.none;

  LoadedFoldersState copyWith({
    List<LoadedFolder>? folders,
    LoadStage? stage,
    int? done,
    int? total,
    int? coversSeq,
  }) => LoadedFoldersState(
    folders: folders ?? this.folders,
    stage: stage ?? this.stage,
    done: done ?? this.done,
    total: total ?? this.total,
    coversSeq: coversSeq ?? this.coversSeq,
  );

  @override
  List<Object?> get props => [folders, stage, done, total, coversSeq];
}

/// 불러오는 폴더 목록 (확인 · 추가 · 삭제). 목록이 바뀌면 보관함을 다시 스캔하고,
/// 새로 들어온 곡의 파일 태그(제목 · 아티스트 · 앨범 · 장르 · 커버 편집 상태)와 내장 커버를 읽어 채운다.
class LoadedFoldersCubit extends Cubit<LoadedFoldersState> {
  LoadedFoldersCubit(
    this._load,
    this._add,
    this._remove,
    this._import, [
    this._restoreTags,
    this._fillCovers,
  ]) : super(const LoadedFoldersState());

  final LoadLoadedFolders _load;
  final AddLoadedFolder _add;
  final RemoveLoadedFolder _remove;
  final ImportDeviceMusic _import;
  final RestoreFromFileTags? _restoreTags;
  final FillEmbeddedCovers? _fillCovers;
  bool _cancelled = false;

  Future<void> load() async {
    final folders = await _load(const NoParams());
    if (!isClosed) emit(state.copyWith(folders: folders));
  }

  /// 폴더를 골라 더하고 곡을 불러온다. 끝까지 불러왔으면 true (취소해서 폴더 등록을 되돌렸으면 false).
  Future<bool> add() async {
    if (state.busy) return false;
    final result = await _add(const NoParams());
    if (result != AddFolderResult.added) return false;
    final known = {for (final f in state.folders) f.path};
    final folders = await _load(const NoParams());
    final added = [
      for (final f in folders)
        if (!known.contains(f.path)) f.path,
    ];
    await _rescan(
      onCancelled: added.isEmpty
          ? null
          : () async {
              // 취소하면 방금 등록한 폴더를 목록에서 빼고, 거기서 불러온 곡도 보관함에서 지운다.
              _stage(LoadStage.removing);
              await _remove(added.first);
            },
    );
    return !_cancelled;
  }

  /// 폴더를 더하는 중이면 등록을 취소한다 (폴더와 불러온 곡을 되돌린다). 빼는 중이면 지우기를 멈추고 되돌린다.
  void cancel() => _cancelled = true;

  /// 폴더를 빼고, 보관함에서 지운 곡의 id를 돌려준다 (재생 대기열에서도 빼도록).
  Future<Set<String>> remove(String path) async {
    if (state.busy) return const {};
    _cancelled = false;
    _stage(LoadStage.removing);
    final removed = await _remove(path, cancelled: () => _cancelled);
    // 중간에 취소하면 폴더는 목록에 남고, 이미 지운 곡은 다시 불러온다.
    if (_cancelled && removed != null && removed.isNotEmpty) {
      _cancelled = false;
      await _rescan();
      return removed;
    }
    // 뺀 폴더의 곡은 이미 보관함에서 지웠고 남은 폴더는 그대로라 다시 찾지 않는다.
    final folders = await _load(const NoParams());
    if (!isClosed) {
      emit(LoadedFoldersState(folders: folders, coversSeq: state.coversSeq));
    }
    return removed ?? const {};
  }

  void _stage(LoadStage stage, [int done = 0, int total = 0]) {
    if (!isClosed) {
      emit(state.copyWith(stage: stage, done: done, total: total));
    }
  }

  Future<void> _rescan({Future<void> Function()? onCancelled}) async {
    _cancelled = false;
    _stage(LoadStage.scanning);
    await load();
    final outcome = await _import(const NoParams());
    var changed = false;
    if (outcome is ImportAdded && !_cancelled) {
      final restore = _restoreTags;
      if (restore != null) {
        _stage(LoadStage.reading);
        try {
          changed |=
              await restore.run(
                onProgress: (d, t) => _stage(LoadStage.reading, d, t),
                cancelled: () => _cancelled,
              ) >
              0;
        } on Exception {
          // 못 읽어도 폴더 바꾸기에는 영향이 없다 (곡마다 기록해 다음에 이어서).
        }
      }
      final fill = _fillCovers;
      if (fill != null && !_cancelled) {
        _stage(LoadStage.covers);
        try {
          changed |=
              await fill.run(
                onProgress: (d, t) => _stage(LoadStage.covers, d, t),
                cancelled: () => _cancelled,
              ) >
              0;
        } on Exception {
          // 커버를 못 채워도 폴더 바꾸기에는 영향이 없다.
        }
      }
    }
    if (isClosed) return;
    if (_cancelled && onCancelled != null) await onCancelled();
    final folders = await _load(const NoParams());
    if (isClosed) return;
    emit(
      LoadedFoldersState(
        folders: folders,
        coversSeq: state.coversSeq + (changed ? 1 : 0),
      ),
    );
  }
}
