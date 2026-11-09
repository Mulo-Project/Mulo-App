import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/video_quality.dart';
import '../../domain/usecases/search_usecases.dart';

/// 미리 듣기 영상 화질. 바꾸면 저장하고, 다음에 시작하는 미리 듣기부터 적용된다.
class VideoQualityCubit extends Cubit<VideoQuality> {
  VideoQualityCubit(this._load, this._save) : super(VideoQuality.standard);

  final LoadVideoQuality _load;
  final SaveVideoQuality _save;
  bool _touched = false;

  Future<void> load() async {
    final saved = await _load(const NoParams());
    if (_touched || isClosed) return;
    emit(saved);
  }

  Future<void> set(VideoQuality value) async {
    _touched = true;
    emit(value);
    await _save(value);
  }
}
