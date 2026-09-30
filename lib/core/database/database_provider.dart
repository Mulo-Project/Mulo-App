import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// 앱 전체에서 하나만 여는 DB. 테스트는 메모리 DB로 바꿔 끼운다.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
