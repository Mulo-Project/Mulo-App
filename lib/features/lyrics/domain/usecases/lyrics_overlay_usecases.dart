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
  const ShowLyricsOverlayParams(
    this.trackId,
    this.lines, {
    required this.hideLabel,
    required this.offLabel,
    required this.accent,
    this.emptyLabel = '',
  });

  final String trackId;
  final List<LyricLine> lines;
  final String hideLabel;
  final String offLabel;
  final int accent;

  /// 싱크 가사가 없을 때 창에 대신 보일 글.
  final String emptyLabel;
}

class ShowLyricsOverlay implements UseCase<void, ShowLyricsOverlayParams> {
  const ShowLyricsOverlay(this._overlay);

  final LyricsOverlay _overlay;

  @override
  Future<void> call(ShowLyricsOverlayParams p) => _overlay.show(
    p.trackId,
    p.lines,
    hideLabel: p.hideLabel,
    offLabel: p.offLabel,
    accent: p.accent,
    emptyLabel: p.emptyLabel,
  );
}

class WatchLyricsOverlayClosed implements StreamUseCase<void, NoParams> {
  const WatchLyricsOverlayClosed(this._overlay);

  final LyricsOverlay _overlay;

  @override
  Stream<void> call(NoParams _) => _overlay.watchClosed();
}

class SetLyricsViewShown implements UseCase<void, bool> {
  const SetLyricsViewShown(this._overlay);

  final LyricsOverlay _overlay;

  @override
  Future<void> call(bool shown) => _overlay.setLyricsViewShown(shown);
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
