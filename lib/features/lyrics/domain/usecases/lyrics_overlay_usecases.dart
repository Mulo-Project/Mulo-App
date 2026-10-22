import '../../../../core/usecase/usecase.dart';
import '../entities/lyrics.dart';
import '../repositories/lyrics_overlay.dart';
import '../repositories/lyrics_settings_repository.dart';

class CanDrawLyricsOverlay implements UseCase<bool, NoParams> {
  const CanDrawLyricsOverlay(this._overlay);

  final LyricsOverlay _overlay;

  @override
  Future<bool> call(NoParams _) => _overlay.canDraw();
}

class OpenLyricsOverlayPermission implements UseCase<void, NoParams> {
  const OpenLyricsOverlayPermission(this._overlay);

  final LyricsOverlay _overlay;

  @override
  Future<void> call(NoParams _) => _overlay.openPermissionSettings();
}

class ShowLyricsOverlayParams {
  const ShowLyricsOverlayParams(this.trackId, this.lines);

  final String trackId;
  final List<LyricLine> lines;
}

class ShowLyricsOverlay implements UseCase<void, ShowLyricsOverlayParams> {
  const ShowLyricsOverlay(this._overlay);

  final LyricsOverlay _overlay;

  @override
  Future<void> call(ShowLyricsOverlayParams p) =>
      _overlay.show(p.trackId, p.lines);
}

class HideLyricsOverlay implements UseCase<void, NoParams> {
  const HideLyricsOverlay(this._overlay);

  final LyricsOverlay _overlay;

  @override
  Future<void> call(NoParams _) => _overlay.hide();
}

class SaveLyricsOverlaySetting implements UseCase<void, bool> {
  const SaveLyricsOverlaySetting(this._repo);

  final LyricsSettingsRepository _repo;

  @override
  Future<void> call(bool on) => _repo.saveOverlay(on);
}
