import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/di/injector.dart';
import 'core/sample/sample_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  // 디버그 빌드: 보관함이 비어 있으면 샘플 데이터로 화면을 채운다.
  if (kDebugMode) await seedSampleData(sl<AppDatabase>());
  runApp(const MusicApp());
}
