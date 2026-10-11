import 'package:get_it/get_it.dart';

import 'data/repositories/prefs_theme_settings_repository.dart';
import 'domain/repositories/theme_settings_repository.dart';
import 'domain/usecases/theme_usecases.dart';
import 'presentation/bloc/theme_cubit.dart';

/// 테마 기능 의존성. 테스트는 [ThemeSettingsRepository]만 바꿔 끼운다.
void registerTheme(GetIt sl) {
  sl
    ..registerLazySingleton<ThemeSettingsRepository>(
      PrefsThemeSettingsRepository.new,
    )
    ..registerFactory(() => LoadThemeSettings(sl()))
    ..registerFactory(() => SaveThemePreset(sl()))
    ..registerFactory(() => SaveThemeMode(sl()))
    ..registerFactory(() => SaveFollowMood(sl()))
    ..registerFactory(
      () => ThemeCubit(
        loadSettings: sl(),
        savePreset: sl(),
        saveMode: sl(),
        saveFollowMood: sl(),
      ),
    );
}
