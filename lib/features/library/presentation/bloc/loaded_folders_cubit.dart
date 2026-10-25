import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/loaded_folder.dart';
import '../../domain/usecases/library_usecases.dart';
import '../../domain/usecases/loaded_folder_usecases.dart';

class LoadedFoldersState extends Equatable {
  const LoadedFoldersState({this.folders = const [], this.busy = false});

  /// 기본 저장 위치가 맨 위.
  final List<LoadedFolder> folders;

  /// 폴더를 바꾸고 보관함을 다시 찾는 중.
  final bool busy;

  @override
  List<Object?> get props => [folders, busy];
}

/// 불러오는 폴더 목록 (확인 · 추가 · 삭제). 목록이 바뀌면 보관함을 다시 스캔한다.
class LoadedFoldersCubit extends Cubit<LoadedFoldersState> {
  LoadedFoldersCubit(this._load, this._add, this._remove, this._import)
    : super(const LoadedFoldersState());

  final LoadLoadedFolders _load;
  final AddLoadedFolder _add;
  final RemoveLoadedFolder _remove;
  final ImportDeviceMusic _import;

  Future<void> load() async {
    final folders = await _load(const NoParams());
    if (!isClosed) emit(LoadedFoldersState(folders: folders, busy: state.busy));
  }

  Future<void> add() async {
    if (state.busy) return;
    final result = await _add(const NoParams());
    if (result == AddFolderResult.added) await _rescan();
  }

  /// 폴더를 빼고, 보관함에서 지운 곡의 id를 돌려준다 (재생 대기열에서도 빼도록).
  Future<Set<String>> remove(String path) async {
    if (state.busy) return const {};
    final removed = await _remove(path);
    if (removed == null) return const {};
    await _rescan();
    return removed;
  }

  Future<void> _rescan() async {
    emit(LoadedFoldersState(folders: state.folders, busy: true));
    await load();
    await _import(const NoParams());
    if (isClosed) return;
    emit(LoadedFoldersState(folders: await _load(const NoParams())));
  }
}
