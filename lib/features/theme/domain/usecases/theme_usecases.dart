import '../../../../core/usecase/usecase.dart';
import '../entities/theme_settings.dart';
import '../repositories/theme_settings_repository.dart';

class LoadThemeSettings implements UseCase<ThemeSettings, NoParams> {
  const LoadThemeSettings(this._repo);

  final ThemeSettingsRepository _repo;

  @override
  Future<ThemeSettings> call(NoParams _) => _repo.load();
}

class SaveThemePreset implements UseCase<void, String> {
  const SaveThemePreset(this._repo);

  final ThemeSettingsRepository _repo;

  @override
  Future<void> call(String presetId) => _repo.savePreset(presetId);
}

class SaveThemeMode implements UseCase<void, AppThemeMode> {
  const SaveThemeMode(this._repo);

  final ThemeSettingsRepository _repo;

  @override
  Future<void> call(AppThemeMode mode) => _repo.saveMode(mode);
}
