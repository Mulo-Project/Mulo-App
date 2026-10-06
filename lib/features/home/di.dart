import 'package:get_it/get_it.dart';

import 'data/repositories/drift_play_history_repository.dart';
import 'data/repositories/prefs_join_date_repository.dart';
import 'domain/repositories/join_date_repository.dart';
import 'domain/repositories/play_history_repository.dart';
import 'domain/usecases/home_usecases.dart';
import 'presentation/bloc/home_bloc.dart';
import 'presentation/bloc/play_recorder_cubit.dart';

/// 홈 · 재생 기록 의존성. 보관함 리포지토리는 library 기능이 등록한다.
void registerHome(GetIt sl) {
  sl
    ..registerLazySingleton<PlayHistoryRepository>(
      () => DriftPlayHistoryRepository(sl()),
    )
    ..registerLazySingleton<JoinDateRepository>(PrefsJoinDateRepository.new)
    ..registerFactory(() => RecordPlay(sl()))
    ..registerFactory(() => UpdatePlayListened(sl()))
    ..registerFactory(() => WatchHomeSummary(sl(), sl()))
    ..registerFactory(() => GetJoinDate(sl()))
    ..registerFactory(() => HomeBloc(sl(), sl()))
    ..registerFactory(() => PlayRecorderCubit(sl(), sl()));
}
