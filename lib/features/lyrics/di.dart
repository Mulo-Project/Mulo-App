import 'package:get_it/get_it.dart';

import 'data/datasources/file_picker_lyrics_source.dart';
import 'data/datasources/tag_lyrics_source.dart';
import 'data/repositories/drift_lyrics_repository.dart';
import 'domain/repositories/lyrics_repository.dart';
import 'domain/usecases/lyrics_usecases.dart';
import 'presentation/bloc/lyrics_cubit.dart';

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
    );
}
