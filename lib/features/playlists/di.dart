import 'package:get_it/get_it.dart';

import 'data/repositories/drift_playlist_repository.dart';
import 'domain/repositories/playlist_repository.dart';
import 'domain/usecases/playlist_usecases.dart';
import 'presentation/bloc/playlists_cubit.dart';

/// 재생목록 의존성.
void registerPlaylists(GetIt sl) {
  sl
    ..registerLazySingleton<PlaylistRepository>(
      () => DriftPlaylistRepository(sl()),
    )
    ..registerFactory(() => WatchPlaylists(sl()))
    ..registerFactory(() => CreatePlaylist(sl()))
    ..registerFactory(() => AddTrackToPlaylists(sl()))
    ..registerFactory(() => RemoveTrackFromPlaylist(sl()))
    ..registerFactory(() => SetPlaylistColor(sl()))
    ..registerFactory(() => PlaylistsCubit(sl(), sl(), sl(), sl(), sl()));
}
