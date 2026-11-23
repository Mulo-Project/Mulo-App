import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/mix_with_others_usecases.dart';

/// "다른 앱과 함께 재생" 켜짐 여부. 바꾸면 저장하고 재생 엔진에 반영한다.
class MixWithOthersCubit extends Cubit<bool> {
  MixWithOthersCubit({
    required LoadMixWithOthers loadMix,
    required SaveMixWithOthers saveMix,
  }) : _load = loadMix,
       _save = saveMix,
       super(false);

  final LoadMixWithOthers _load;
  final SaveMixWithOthers _save;
  bool _touched = false;

  Future<void> load() async {
    final saved = await _load(const NoParams());
    if (_touched || isClosed) return;
    emit(saved);
  }

  Future<void> set(bool value) async {
    _touched = true;
    emit(value);
    await _save(value);
  }
}
