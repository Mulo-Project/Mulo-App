import 'package:get_it/get_it.dart';

import 'data/datasources/file_picker_image_source.dart';
import 'data/repositories/drift_cover_repository.dart';
import 'domain/repositories/cover_repository.dart';
import 'domain/usecases/cover_usecases.dart';
import 'presentation/bloc/cover_cubit.dart';

void registerCovers(GetIt sl) {
  sl
    ..registerLazySingleton<CoverRepository>(() => DriftCoverRepository(sl()))
    ..registerLazySingleton<CoverImageSource>(FilePickerImageSource.new)
    ..registerFactory(() => LoadCovers(sl()))
    ..registerFactory(() => PickCoverFromDevice(sl(), sl()))
    ..registerFactory(() => ClearCover(sl()))
    ..registerFactory(
      () => CoverCubit(load: sl(), pickFromDevice: sl(), clear: sl()),
    );
}
