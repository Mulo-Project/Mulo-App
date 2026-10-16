import 'package:get_it/get_it.dart';

import 'data/datasources/file_picker_lyrics_source.dart';
import 'data/datasources/tag_lyrics_source.dart';
import 'data/repositories/prefs_lyrics_settings_repository.dart';
import 'data/repositories/drift_lyrics_repository.dart';
import 'domain/repositories/lyrics_repository.dart';
import 'domain/repositories/lyrics_settings_repository.dart';
import 'domain/usecases/lyrics_settings_usecases.dart';
import 'domain/usecases/lyrics_usecases.dart';
import 'presentation/bloc/lyrics_cubit.dart';
import 'presentation/bloc/lyrics_settings_cubit.dart';

void registerLyrics(GetIt sl) {
  sl
    ..registerLazySingleton<LyricsRepository>(
      () => DriftLyricsRepository(sl(), sl()),
    )
    ..registerLazySingleton<EmbeddedLyricsSource>(TagLyricsSource.new)
    ..registerLazySingleton<LyricsFileSource>(FilePickerLyricsSource.new)
    ..registerFactory(() => LoadLyrics(sl()))
    ..registerFactory(() => SaveLyrics(sl()))
    ..registerFactory(() => ClearLyrics(sl()))
    ..registerFactory(() => PickLyricsFile(sl()))
    ..registerFactory(
      () => LyricsCubit(load: sl(), save: sl(), clear: sl(), pickFile: sl()),
    )
    ..registerLazySingleton<LyricsSettingsRepository>(
      PrefsLyricsSettingsRepository.new,
    )
    ..registerFactory(() => LoadLyricsSettings(sl()))
    ..registerFactory(() => SaveStampLatency(sl()))
    ..registerFactory(() => SaveLyricsTheme(sl()))
    ..registerFactory(
      () => LyricsSettingsCubit(
        loadSettings: sl(),
        saveStampLatency: sl(),
        saveLyricsTheme: sl(),
      ),
    );
}
