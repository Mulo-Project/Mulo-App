import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/equalizer_settings.dart';
import '../../domain/usecases/equalizer_usecases.dart';

class EqualizerState extends Equatable {
  const EqualizerState({
    this.info,
    this.settings = const EqualizerSettings(),
    this.saved = const EqualizerSettings(),
    this.loaded = false,
    this.device,
  });

  /// 기기 능력. 읽기 전이거나 이퀄라이저를 쓸 수 없으면 null.
  final EqualizerInfo? info;

  /// 지금 소리에 반영된 값 (저장 전 손본 값 포함).
  final EqualizerSettings settings;

  /// 마지막으로 저장한 값.
  final EqualizerSettings saved;
  final bool loaded;

  /// 지금 출력 기기 (알 수 없으면 null). 기기마다 전용 값을 둘 수 있다.
  final EqualizerDevice? device;

  bool get supported => info != null;

  /// 저장하지 않은 변경이 있다.
  bool get dirty => settings != saved;

  @override
  List<Object?> get props => [info, settings, saved, loaded, device];
}

/// 이퀄라이저. 켜고 끄기는 바로 저장하고, 소리를 다듬는 값(프리셋 · 대역 · 효과)은 손대는 즉시 소리에는
/// 반영하되 [save]를 눌러야 저장한다. 저장하지 않고 화면을 나가면 [discard]로 저장된 값으로 되돌린다.
class EqualizerCubit extends Cubit<EqualizerState> {
  EqualizerCubit({
    required LoadEqualizer loadEqualizer,
    required ApplyEqualizer applyEqualizer,
    required SaveEqualizer saveEqualizer,
    required SetEqualizerDeviceProfile setDeviceProfile,
    required WatchEqualizerDevice watchDevice,
  }) : _load = loadEqualizer,
       _apply = applyEqualizer,
       _save = saveEqualizer,
       _setProfile = setDeviceProfile,
       _watch = watchDevice,
       super(const EqualizerState());

  final LoadEqualizer _load;
  final ApplyEqualizer _apply;
  final SaveEqualizer _save;
  final SetEqualizerDeviceProfile _setProfile;
  final WatchEqualizerDevice _watch;
  StreamSubscription<void>? _deviceChanges;

  Future<void> load() async {
    await _reload();
    if (isClosed || _deviceChanges != null || !state.supported) return;
    // 출력 기기가 바뀌면 네이티브가 새 기기의 값을 적용한다: 화면도 그 값을 따라간다.
    final changes = await _watch(const NoParams());
    if (isClosed) return;
    _deviceChanges = changes.listen((_) {
      // 손보던 값이 있으면 덮어쓰지 않는다.
      if (!state.dirty) _reload();
    });
  }

  Future<void> _reload() async {
    final setup = await _load(const NoParams());
    if (isClosed) return;
    emit(
      EqualizerState(
        info: setup.info,
        settings: setup.settings,
        saved: setup.settings,
        loaded: true,
        device: setup.device,
      ),
    );
  }

  /// 지금 출력 기기 전용 값으로 따로 저장할지. 켜면 지금 값이 이 기기 전용이 되고,
  /// 끄면 이 기기도 기본 저장 값을 쓴다.
  Future<void> setDeviceProfile(bool value) async {
    await _setProfile((enabled: value, settings: state.settings));
    await _reload();
  }

  /// 켜고 끄기는 설정이라 바로 저장한다 (저장 전 손본 값은 저장하지 않고 그대로 둔다).
  Future<void> setEnabled(bool value) async {
    final next = state.settings.copyWith(enabled: value);
    final saved = state.saved.copyWith(enabled: value);
    _emit(next, saved: saved);
    _apply(next);
    await _save(saved);
  }

  void selectPreset(EqualizerPreset preset) {
    final info = state.info;
    if (info == null || preset == EqualizerPreset.custom) return;
    _preview(
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

  void setBand(int band, double db) {
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

  void setBassBoost(double value) =>
      _preview(state.settings.copyWith(bassBoost: value.clamp(0.0, 1.0)));

  void setVirtualizer(double value) =>
      _preview(state.settings.copyWith(virtualizer: value.clamp(0.0, 1.0)));

  void selectReverb(EqualizerReverb reverb) =>
      _preview(state.settings.copyWith(reverb: reverb));

  /// 만들어 둔 프리셋의 값을 소리에 반영한다 (저장은 [save]를 눌러야 한다).
  void applyUserPreset(EqualizerSettings preset) {
    final info = state.info;
    if (info == null) return;
    _preview(preset.fitTo(info).copyWith(enabled: state.settings.enabled));
  }

  void setLimiter(bool value) =>
      _preview(state.settings.copyWith(limiter: value));

  /// 소리를 다듬는 값을 평평한 기본으로 되돌린다 (저장은 [save]를 눌러야 한다).
  void reset() {
    final info = state.info;
    if (info == null) return;
    _preview(
      state.settings.copyWith(
        preset: EqualizerPreset.flat,
        levels: EqualizerPreset.flat.levelsFor(info.bandHz.length),
        bassBoost: 0,
        virtualizer: 0,
        reverb: EqualizerReverb.none,
        limiter: true,
      ),
    );
  }

  /// 지금 값을 저장한다.
  Future<void> save() async {
    final now = state.settings;
    _emit(now, saved: now);
    await _save(now);
  }

  /// 저장하지 않은 변경을 버리고 저장된 값으로 소리를 되돌린다.
  void discard() {
    if (!state.dirty) return;
    _emit(state.saved);
    _apply(state.saved);
  }

  void _preview(EqualizerSettings next) {
    _emit(next);
    _apply(next);
  }

  void _emit(EqualizerSettings next, {EqualizerSettings? saved}) => emit(
    EqualizerState(
      info: state.info,
      settings: next,
      saved: saved ?? state.saved,
      loaded: true,
      device: state.device,
    ),
  );

  @override
  Future<void> close() {
    _deviceChanges?.cancel();
    return super.close();
  }
}
