import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/entities/download_preferences.dart';
import '../../domain/usecases/download_usecases.dart';

/// 설정의 기본 음질 · 저장 형식. 받을 때(대기열)가 이 값을 읽어 쓴다.
class DownloadPreferencesCubit extends Cubit<DownloadPreferences> {
  DownloadPreferencesCubit(this._load, this._saveQuality, this._saveFormat)
    : super(const DownloadPreferences());

  final LoadDownloadPreferences _load;
  final SaveDownloadQuality _saveQuality;
  final SaveDownloadFormat _saveFormat;

  Future<void> load() async {
    final prefs = await _load(const NoParams());
    if (!isClosed) emit(prefs);
  }

  Future<void> setQuality(Quality quality) async {
    emit(state.copyWith(quality: quality));
    await _saveQuality(quality);
  }

  Future<void> setFormat(AudioFormat format) async {
    emit(state.copyWith(format: format));
    await _saveFormat(format);
  }
}
