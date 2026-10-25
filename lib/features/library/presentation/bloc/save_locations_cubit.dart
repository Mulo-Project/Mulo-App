import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/loaded_folder_usecases.dart';

/// 저장 위치 목록 (기본 저장 위치가 맨 위). 불러오는 폴더 목록과는 따로 움직인다.
class SaveLocationsCubit extends Cubit<List<String>> {
  SaveLocationsCubit(this._load, this._add, this._remove) : super(const []);

  final LoadSaveLocations _load;
  final AddSaveLocation _add;
  final RemoveSaveLocation _remove;

  Future<void> load() async {
    final list = await _load(const NoParams());
    if (!isClosed) emit(list);
  }

  Future<void> add(String path) async {
    await _add(path);
    await load();
  }

  Future<void> remove(String path) async {
    await _remove(path);
    await load();
  }
}
