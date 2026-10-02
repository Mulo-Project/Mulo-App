import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/download_usecases.dart';

/// 다운로드 기본 저장 위치. 설정에서 바꾸고, 받기 팝업이 이 값으로 채워 시작한다.
class DownloadSettingsCubit extends Cubit<String> {
  DownloadSettingsCubit(this._load, this._save, this._pick) : super('');

  final LoadSavePath _load;
  final SaveSavePath _save;
  final PickSaveFolder _pick;

  Future<void> load() async {
    final path = await _load(const NoParams());
    if (!isClosed) emit(path);
  }

  Future<void> setSavePath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    emit(trimmed);
    await _save(trimmed);
  }

  /// 폴더 선택기로 고른 폴더. 취소하면 null (저장하지 않는다).
  Future<String?> pickFolder() => _pick(const NoParams());

  /// 선택기로 고른 폴더를 기본 저장 위치로 정한다. 정했으면 true.
  Future<bool> pickAndSave() async {
    final path = await pickFolder();
    if (path == null || isClosed) return false;
    await setSavePath(path);
    return true;
  }
}
