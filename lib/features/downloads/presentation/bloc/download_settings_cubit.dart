import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/download_usecases.dart';

/// 다운로드 저장 위치. 상태는 **고정한(체크한) 폴더**이고, 고정하지 않았으면 빈 문자열이다.
/// 고정하지 않으면 마지막에 받은 폴더에, 그것도 없으면 앱 기본 폴더에 받는다 ([effectivePath]).
class DownloadSettingsCubit extends Cubit<String> {
  DownloadSettingsCubit(
    this._loadEffective,
    this._save,
    this._pick,
    this._loadFixed,
    this._clear,
  ) : super('');

  final LoadSavePath _loadEffective;
  final SaveSavePath _save;
  final PickSaveFolder _pick;
  final LoadFixedSavePath _loadFixed;
  final ClearSavePath _clear;

  Future<void> load() async {
    final path = await _loadFixed(const NoParams());
    if (!isClosed) emit(path);
  }

  /// 지금 받으면 쓰일 폴더 (고정한 폴더 → 마지막에 받은 폴더 → 앱 기본 폴더).
  Future<String> effectivePath() => _loadEffective(const NoParams());

  /// 저장 위치를 고정한다.
  Future<void> setSavePath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    emit(trimmed);
    await _save(trimmed);
  }

  /// 고정을 푼다.
  Future<void> clearSavePath() async {
    emit('');
    await _clear(const NoParams());
  }

  /// 폴더 선택기로 고른 폴더. 취소하면 null (저장하지 않는다).
  Future<String?> pickFolder() => _pick(const NoParams());

  /// 선택기로 고른 폴더를 고정한다. 정했으면 true.
  Future<bool> pickAndSave() async {
    final path = await pickFolder();
    if (path == null || isClosed) return false;
    await setSavePath(path);
    return true;
  }
}
