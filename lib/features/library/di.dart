import 'dart:io';

import 'package:get_it/get_it.dart';

import 'data/datasources/device_music_data_sources.dart';
import 'data/datasources/embedded_cover_source.dart';
import 'data/datasources/file_tag_source.dart';
import 'data/repositories/embedded_cover_repository_impl.dart';
import 'data/repositories/device_music_repository_impl.dart';
import 'data/repositories/drift_library_repository.dart';
import 'data/datasources/track_file_data_source.dart';
import 'data/repositories/prefs_loaded_folder_repository.dart';
import 'data/repositories/track_file_repository_impl.dart';
import 'data/datasources/track_tag_source.dart';
import 'data/repositories/track_tag_repository_impl.dart';
import 'domain/repositories/track_tag_repository.dart';
import 'domain/repositories/library_repository.dart';
import 'domain/usecases/library_usecases.dart';
import 'domain/usecases/loaded_folder_usecases.dart';
import 'presentation/bloc/hidden_records_cubit.dart';
import 'presentation/bloc/library_cubit.dart';
import 'presentation/bloc/library_import_cubit.dart';
import 'presentation/bloc/loaded_folders_cubit.dart';
import 'presentation/bloc/save_locations_cubit.dart';

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
    ..registerLazySingleton<EmbeddedCoverRepository>(
      () => EmbeddedCoverRepositoryImpl(
        EmbeddedCoverSource(
          Platform.isAndroid ? MediaStorePictureReader() : FilePictureReader(),
        ),
      ),
    )
    ..registerLazySingleton<TrackTagRepository>(
      () => TrackTagRepositoryImpl(TrackTagSource()),
    )
    ..registerLazySingleton<TagMigrationStore>(PrefsTagMigrationStore.new)
    ..registerLazySingleton<FileTagRepository>(
      () => FileTagRepositoryImpl(FileTagSource()),
    )
    ..registerLazySingleton<TagRestoreStore>(PrefsTagRestoreStore.new)
    ..registerLazySingleton<LibraryRepository>(
      () => DriftLibraryRepository(sl()),
    )
    ..registerLazySingleton<TrackFileDataSource>(
      PlatformTrackFileDataSource.new,
    )
    ..registerLazySingleton<TrackFileRepository>(
      () => TrackFileRepositoryImpl(sl()),
    )
    ..registerLazySingleton<LoadedFolderRepository>(
      PrefsLoadedFolderRepository.new,
    )
    ..registerFactory(() => WatchLibraryTracks(sl(), sl()))
    ..registerFactory(() => UpdateTrackInfo(sl(), sl()))
    ..registerFactory(() => EmbedTagsIntoFiles(sl(), sl(), sl(), sl(), sl()))
    ..registerFactory(() => RestoreFromFileTags(sl(), sl(), sl(), sl(), sl()))
    ..registerFactory(() => DeleteTrack(sl(), sl()))
    ..registerFactory(() => GetTrackFileInfo(sl()))
    ..registerFactory(() => ImportDeviceMusic(sl(), sl(), sl()))
    ..registerFactory(() => LoadLoadedFolders(sl(), sl()))
    ..registerFactory(() => AddLoadedFolder(sl()))
    ..registerFactory(() => RemoveLoadedFolder(sl(), sl()))
    ..registerFactory(() => ListHiddenTracks(sl()))
    ..registerFactory(() => PurgeHiddenTracks(sl()))
    ..registerFactory(() => HiddenRecordsCubit(sl(), sl()))
    ..registerFactory(
      () => LoadedFoldersCubit(sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => LoadSaveLocations(sl()))
    ..registerFactory(() => AddSaveLocation(sl()))
    ..registerFactory(() => RemoveSaveLocation(sl()))
    ..registerFactory(() => SaveLocationsCubit(sl(), sl(), sl()))
    ..registerFactory(() => LibraryCubit(sl(), sl(), sl()))
    ..registerFactory(() => FillEmbeddedCovers(sl(), sl(), sl()))
    ..registerFactory(() => LibraryImportCubit(sl(), sl(), sl(), sl()));
}
