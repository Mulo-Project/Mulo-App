import 'package:get_it/get_it.dart';

import 'data/datasources/file_picker_image_source.dart';
import 'data/repositories/drift_cover_color_repository.dart';
import 'data/repositories/drift_cover_repository.dart';
import 'domain/repositories/cover_repository.dart';
import 'domain/usecases/cover_usecases.dart';
import 'presentation/bloc/cover_color_cubit.dart';
import 'presentation/bloc/cover_cubit.dart';
import 'presentation/bloc/cover_web_cubit.dart';

void registerCovers(GetIt sl) {
  sl
    ..registerLazySingleton<CoverRepository>(() => DriftCoverRepository(sl()))
    ..registerLazySingleton<CoverColorRepository>(
      () => DriftCoverColorRepository(sl()),
    )
    ..registerLazySingleton<CoverImageSource>(FilePickerImageSource.new)
    ..registerFactory(() => LoadCovers(sl()))
    ..registerFactory(() => ClearCover(sl()))
    ..registerFactory(() => PickImageFile(sl()))
    ..registerFactory(() => SaveCover(sl()))
    ..registerFactory(() => SaveWebCover(sl()))
    ..registerFactory(() => SetCoverTransform(sl()))
    ..registerFactory(() => LoadCoverColors(sl()))
    ..registerFactory(() => SetCoverColor(sl()))
    ..registerFactory(() => ClearCoverColor(sl()))
    ..registerFactory(() => CoverColorCubit(load: sl(), set: sl(), clear: sl()))
    ..registerFactory(
      () => CoverCubit(
        load: sl(),
        clear: sl(),
        pickFile: sl(),
        save: sl(),
        saveWeb: sl(),
        setTransform: sl(),
      ),
    )
    ..registerFactory(() => CoverWebCubit(sl()));
}
