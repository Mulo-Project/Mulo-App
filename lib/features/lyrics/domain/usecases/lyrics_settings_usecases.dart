import '../../../../core/usecase/usecase.dart';
import '../entities/lyrics_settings.dart';
import '../repositories/lyrics_settings_repository.dart';

class LoadLyricsSettings implements UseCase<LyricsSettings, NoParams> {
  const LoadLyricsSettings(this._repo);

  final LyricsSettingsRepository _repo;

  @override
  Future<LyricsSettings> call(NoParams _) => _repo.load();
}

/// 지금을 누를 때 앞당길 시간(밀리초)을 저장한다.
class SaveStampLatency implements UseCase<void, int> {
  const SaveStampLatency(this._repo);

  final LyricsSettingsRepository _repo;

  @override
  Future<void> call(int milliseconds) => _repo.saveLatency(milliseconds);
}

class SaveLyricsTheme implements UseCase<void, LyricsTheme> {
  const SaveLyricsTheme(this._repo);

  final LyricsSettingsRepository _repo;

  @override
  Future<void> call(LyricsTheme theme) => _repo.saveTheme(theme);
}

class SaveLyricsCoverBackground implements UseCase<void, bool> {
  const SaveLyricsCoverBackground(this._repo);

  final LyricsSettingsRepository _repo;

  @override
  Future<void> call(bool on) => _repo.saveCoverBackground(on);
}
