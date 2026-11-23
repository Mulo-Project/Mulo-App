import '../entities/player_style.dart';

/// 고른 플레이어 모양 저장소.
abstract interface class PlayerStyleRepository {
  Future<PlayerStyle> load();
  Future<void> save(PlayerStyle style);
}
