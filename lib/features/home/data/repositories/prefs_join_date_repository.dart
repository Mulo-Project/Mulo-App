import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/join_date_repository.dart';

/// 처음 실행한 날을 shared_preferences에 저장한다 (계정이 없어 가입일 = 설치 후 첫 실행).
class PrefsJoinDateRepository implements JoinDateRepository {
  static const _key = 'app.joinedAt';

  @override
  Future<DateTime> joinedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = DateTime.tryParse(prefs.getString(_key) ?? '');
    if (saved != null) return saved;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await prefs.setString(_key, today.toIso8601String());
    return today;
  }
}
