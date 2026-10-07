import 'package:get_it/get_it.dart';

import 'data/repositories/drift_playlist_repository.dart';
import 'domain/repositories/playlist_repository.dart';
import 'domain/usecases/playlist_usecases.dart';
import 'presentation/bloc/playlist_import_cubit.dart';
import 'presentation/bloc/playlist_tracks_cubit.dart';
import 'presentation/bloc/playlists_cubit.dart';

/// 재생목록 의존성.
void registerPlaylists(GetIt sl) {
  sl
    ..registerLazySingleton<PlaylistRepository>(
      () => DriftPlaylistRepository(sl()),
    )
    ..registerFactory(() => WatchPlaylists(sl()))
    ..registerFactory(() => WatchPlaylistTracks(sl()))
    ..registerFactory(() => CreatePlaylist(sl()))
    ..registerFactory(() => RenamePlaylist(sl()))
    ..registerFactory(() => DeletePlaylist(sl()))
    ..registerFactory(() => AddTrackToPlaylists(sl()))
    ..registerFactory(() => AddTracksToPlaylist(sl()))
    ..registerFactory(() => RemoveTrackFromPlaylist(sl()))
    ..registerFactory(
      () => PlaylistsCubit(
        watch: sl(),
        watchTracks: sl(),
        create: sl(),
        rename: sl(),
        delete: sl(),
        addTrack: sl(),
        addTracks: sl(),
        removeTrack: sl(),
      ),
    )
    ..registerFactory(() => PlaylistTracksCubit(sl()))
    ..registerFactory(() => PlaylistImportCubit(sl(), sl(), sl(), sl()));
}
