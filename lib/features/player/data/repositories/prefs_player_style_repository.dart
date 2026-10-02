import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/player_style.dart';
import '../../domain/repositories/player_style_repository.dart';

/// shared_preferences에 플레이어 모양을 저장한다.
class PrefsPlayerStyleRepository implements PlayerStyleRepository {
  static const _key = 'player.style';

  @override
  Future<PlayerStyle> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PlayerStyle.values.asNameMap()[prefs.getString(_key)] ??
        PlayerStyle.initial;
  }

  @override
  Future<void> save(PlayerStyle style) async =>
      (await SharedPreferences.getInstance()).setString(_key, style.name);
}
