import 'dart:io';

import 'package:get_it/get_it.dart';

import 'data/datasources/device_music_data_sources.dart';
import 'data/repositories/device_music_repository_impl.dart';
import 'data/repositories/drift_library_repository.dart';
import 'data/repositories/prefs_loaded_folder_repository.dart';
import 'domain/repositories/library_repository.dart';
import 'domain/usecases/library_usecases.dart';
import 'domain/usecases/loaded_folder_usecases.dart';
import 'presentation/bloc/library_cubit.dart';
import 'presentation/bloc/library_import_cubit.dart';
import 'presentation/bloc/loaded_folders_cubit.dart';

/// 보관함 기능 의존성. 테스트는 리포지토리만 바꿔 끼운다.
void registerLibrary(GetIt sl) {
  sl
    ..registerLazySingleton<DeviceMusicDataSource>(
      () => Platform.isAndroid
          ? MediaStoreMusicDataSource()
          : DirectoryMusicDataSource(),
    )
    ..registerLazySingleton<DeviceMusicRepository>(
      () => DeviceMusicRepositoryImpl(sl()),
    )
    ..registerLazySingleton<LibraryRepository>(
      () => DriftLibraryRepository(sl()),
    )
    ..registerLazySingleton<LoadedFolderRepository>(
      PrefsLoadedFolderRepository.new,
    )
    ..registerFactory(() => WatchLibraryTracks(sl()))
    ..registerFactory(() => ImportDeviceMusic(sl(), sl(), sl()))
    ..registerFactory(() => LoadLoadedFolders(sl(), sl()))
    ..registerFactory(() => AddLoadedFolder(sl()))
    ..registerFactory(() => RemoveLoadedFolder(sl()))
    ..registerFactory(() => LoadedFoldersCubit(sl(), sl(), sl(), sl()))
    ..registerFactory(() => LibraryCubit(sl()))
    ..registerFactory(() => LibraryImportCubit(sl()));
}
