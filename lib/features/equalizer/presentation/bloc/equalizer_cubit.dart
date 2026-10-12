import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/equalizer_settings.dart';
import '../../domain/usecases/equalizer_usecases.dart';

class EqualizerState extends Equatable {
  const EqualizerState({
    this.info,
    this.settings = const EqualizerSettings(),
    this.loaded = false,
  });

  /// 기기 능력. 읽기 전이거나 이퀄라이저를 쓸 수 없으면 null.
  final EqualizerInfo? info;
  final EqualizerSettings settings;
  final bool loaded;

  bool get supported => info != null;

  @override
  List<Object?> get props => [info, settings, loaded];
}

/// 이퀄라이저 켜짐 · 프리셋 · 대역 · 저음 강화. 바꾸면 엔진에 바로 반영하고 저장한다.
/// 슬라이더를 끄는 동안은 `*Preview`로 반영만 하고, 손을 뗄 때 [commit]으로 저장한다.
class EqualizerCubit extends Cubit<EqualizerState> {
  EqualizerCubit({
    required LoadEqualizer loadEqualizer,
    required ApplyEqualizer applyEqualizer,
    required SaveEqualizer saveEqualizer,
  }) : _load = loadEqualizer,
       _apply = applyEqualizer,
       _save = saveEqualizer,
       super(const EqualizerState());

  final LoadEqualizer _load;
  final ApplyEqualizer _apply;
  final SaveEqualizer _save;

  Future<void> load() async {
    final setup = await _load(const NoParams());
    if (isClosed) return;
    emit(
      EqualizerState(info: setup.info, settings: setup.settings, loaded: true),
    );
  }

  Future<void> setEnabled(bool value) =>
      _change(state.settings.copyWith(enabled: value));

  Future<void> selectPreset(EqualizerPreset preset) {
    final info = state.info;
    if (info == null || preset == EqualizerPreset.custom) {
      return Future.value();
    }
    return _change(
      state.settings.copyWith(
        preset: preset,
        levels: preset.levelsFor(
          info.bandHz.length,
          minDb: info.minDb,
          maxDb: info.maxDb,
        ),
      ),
    );
  }

  /// 슬라이더를 끄는 중: 소리와 화면만 바꾼다.
  void setBandPreview(int band, double db) {
    final info = state.info;
    if (info == null || band < 0 || band >= state.settings.levels.length) {
      return;
    }
    final levels = [...state.settings.levels]
      ..[band] = db.clamp(info.minDb, info.maxDb);
    _preview(
      state.settings.copyWith(preset: EqualizerPreset.custom, levels: levels),
    );
  }

  void setBassBoostPreview(double value) =>
      _preview(state.settings.copyWith(bassBoost: value.clamp(0.0, 1.0)));

  /// 슬라이더에서 손을 뗐다: 지금 값을 저장한다.
  Future<void> commit() => _save(state.settings);

  Future<void> reset() {
    final info = state.info;
    if (info == null) return Future.value();
    return _change(
      state.settings.copyWith(
        preset: EqualizerPreset.flat,
        levels: EqualizerPreset.flat.levelsFor(info.bandHz.length),
        bassBoost: 0,
      ),
    );
  }

  void _preview(EqualizerSettings next) {
    emit(EqualizerState(info: state.info, settings: next, loaded: true));
    _apply(next);
  }

  Future<void> _change(EqualizerSettings next) async {
    _preview(next);
    await _save(next);
  }
}
