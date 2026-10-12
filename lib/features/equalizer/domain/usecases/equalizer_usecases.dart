import '../../../../core/usecase/usecase.dart';
import '../entities/equalizer_settings.dart';
import '../repositories/equalizer_repository.dart';

/// 기기 능력과 저장값을 읽고, 저장값을 대역 수에 맞춰 엔진에 반영한다.
class LoadEqualizer implements UseCase<EqualizerSetup, NoParams> {
  const LoadEqualizer(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<EqualizerSetup> call(NoParams _) async {
    final setup = await _repo.load();
    final info = setup.info;
    if (info == null) return setup;
    final fitted = setup.settings.fitTo(info);
    await _repo.apply(fitted);
    return EqualizerSetup(info: info, settings: fitted);
  }
}

class ApplyEqualizer implements UseCase<void, EqualizerSettings> {
  const ApplyEqualizer(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<void> call(EqualizerSettings settings) => _repo.apply(settings);
}

class SaveEqualizer implements UseCase<void, EqualizerSettings> {
  const SaveEqualizer(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<void> call(EqualizerSettings settings) => _repo.save(settings);
}

class SetEqualizerDeviceProfile
    implements UseCase<void, ({bool enabled, EqualizerSettings settings})> {
  const SetEqualizerDeviceProfile(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<void> call(({bool enabled, EqualizerSettings settings}) params) =>
      _repo.setDeviceProfile(params.enabled, params.settings);
}

class WatchEqualizerDevice implements UseCase<Stream<void>, NoParams> {
  const WatchEqualizerDevice(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<Stream<void>> call(NoParams _) async => _repo.watchDevice();
}

class LoadEqualizerPresets
    implements UseCase<List<EqualizerUserPreset>, NoParams> {
  const LoadEqualizerPresets(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<List<EqualizerUserPreset>> call(NoParams _) => _repo.presets();
}

class SaveEqualizerPreset implements UseCase<void, EqualizerUserPreset> {
  const SaveEqualizerPreset(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<void> call(EqualizerUserPreset preset) => _repo.savePreset(preset);
}

class DeleteEqualizerPreset implements UseCase<void, String> {
  const DeleteEqualizerPreset(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<void> call(String id) => _repo.deletePreset(id);
}

class LoadEqualizerDevices implements UseCase<List<EqualizerDevice>, NoParams> {
  const LoadEqualizerDevices(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<List<EqualizerDevice>> call(NoParams _) => _repo.devices();
}

class AssignEqualizerPreset
    implements UseCase<void, ({String deviceKey, String? presetId})> {
  const AssignEqualizerPreset(this._repo);

  final EqualizerRepository _repo;

  @override
  Future<void> call(({String deviceKey, String? presetId}) params) =>
      _repo.assignPreset(params.deviceKey, params.presetId);
}
