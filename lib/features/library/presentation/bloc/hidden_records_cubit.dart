import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/loaded_folder_usecases.dart';

/// 폴더를 빼서 숨겨 둔 곡의 수 (상태)와 그 기록 정리.
class HiddenRecordsCubit extends Cubit<int> {
  HiddenRecordsCubit(this._count, this._purge) : super(0);

  final CountHiddenTracks _count;
  final PurgeHiddenTracks _purge;

  Future<void> load() async {
    final n = await _count(const NoParams());
    if (!isClosed) emit(n);
  }

  /// 숨긴 곡의 기록을 모두 지우고 지운 곡 수를 돌려준다.
  Future<int> purge() async {
    final n = await _purge(const NoParams());
    await load();
    return n;
  }
}
