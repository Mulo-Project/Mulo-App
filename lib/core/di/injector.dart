import 'package:get_it/get_it.dart';

import '../../features/covers/di.dart';
import '../../features/home/di.dart';
import '../../features/library/di.dart';
import '../../features/player/di.dart';
import '../../features/theme/di.dart';
import '../database/app_database.dart';

/// 앱 전체 서비스 찾기 (get_it). 기능마다 `di.dart`의 register 함수로 등록한다.
final sl = GetIt.instance;

/// 앱 시작 때 한 번. 테스트는 [GetIt.reset] 후 가짜를 등록한다 (test/helpers).
void configureDependencies({AppDatabase? database}) {
  sl.registerLazySingleton<AppDatabase>(
    () => database ?? AppDatabase(),
    dispose: (db) => db.close(),
  );
  registerTheme(sl);
  registerLibrary(sl);
  registerCovers(sl);
  registerPlayer(sl);
  registerHome(sl);
}
