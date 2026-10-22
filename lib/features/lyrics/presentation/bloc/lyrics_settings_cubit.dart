import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/lyrics_settings.dart';
import '../../domain/usecases/lyrics_overlay_usecases.dart';
import '../../domain/usecases/lyrics_settings_usecases.dart';

export '../../domain/entities/lyrics_settings.dart';

/// 가사 보기 모양과 지금 반응 시간 보정 설정.
class LyricsSettingsCubit extends Cubit<LyricsSettings> {
  LyricsSettingsCubit({
    required LoadLyricsSettings loadSettings,
    required SaveStampLatency saveStampLatency,
    required SaveLyricsTheme saveLyricsTheme,
    required SaveLyricsCoverBackground saveCoverBackground,
    required this._saveOverlay,
  }) : _load = loadSettings,
       _saveLatency = saveStampLatency,
       _saveTheme = saveLyricsTheme,
       _saveCover = saveCoverBackground,
       super(const LyricsSettings());

  final LoadLyricsSettings _load;
  final SaveStampLatency _saveLatency;
  final SaveLyricsTheme _saveTheme;
  final SaveLyricsCoverBackground _saveCover;
  final SaveLyricsOverlaySetting _saveOverlay;

  Future<void> load() async {
    final settings = await _load(const NoParams());
    if (!isClosed) emit(settings);
  }

  /// 반응 시간 보정(밀리초)을 바꾼다 (0 ~ 500).
  Future<void> setLatency(int milliseconds) async {
    final next = state.copyWith(latencyMs: milliseconds);
    if (next == state) return;
    emit(next);
    await _saveLatency(next.latencyMs);
  }

  Future<void> setTheme(LyricsTheme theme) async {
    if (theme == state.theme) return;
    emit(state.copyWith(theme: theme));
    await _saveTheme(theme);
  }

  Future<void> setCoverBackground(bool on) async {
    if (on == state.coverBackground) return;
    emit(state.copyWith(coverBackground: on));
    await _saveCover(on);
  }

  /// 떠 있는 가사 창을 켜고 끈다 (켜기 전 권한 확인은 부르는 쪽에서).
  Future<void> setOverlay(bool on) async {
    if (on == state.overlay) return;
    emit(state.copyWith(overlay: on));
    await _saveOverlay(on);
  }
}
