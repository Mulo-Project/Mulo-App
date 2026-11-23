import '../../../../core/usecase/usecase.dart';
import '../entities/player_style.dart';
import '../repositories/player_style_repository.dart';

class LoadPlayerStyle implements UseCase<PlayerStyle, NoParams> {
  const LoadPlayerStyle(this._repo);

  final PlayerStyleRepository _repo;

  @override
  Future<PlayerStyle> call(NoParams _) => _repo.load();
}

class SavePlayerStyle implements UseCase<void, PlayerStyle> {
  const SavePlayerStyle(this._repo);

  final PlayerStyleRepository _repo;

  @override
  Future<void> call(PlayerStyle style) => _repo.save(style);
}
