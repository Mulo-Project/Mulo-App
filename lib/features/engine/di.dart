import 'package:get_it/get_it.dart';

import 'data/android_yt_dlp.dart';
import 'data/yt_dlp_manager.dart';
import 'domain/repositories/engine_manager.dart';
import 'domain/usecases/engine_usecases.dart';
import 'presentation/bloc/engine_cubit.dart';

/// 다운로드 엔진(yt-dlp) 설치 의존성.
void registerEngine(GetIt sl) {
  sl
    ..registerLazySingleton<AndroidYtDlp>(AndroidYtDlp.new)
    ..registerLazySingleton<YtDlpManager>(
      () => YtDlpManager(android: sl<AndroidYtDlp>()),
    )
    ..registerLazySingleton<EngineManager>(() => sl<YtDlpManager>())
    ..registerFactory(() => LoadEngineStatus(sl()))
    ..registerFactory(() => InstallEngine(sl()))
    // 설정과 검색 탭이 같은 상태를 보도록 하나만 둔다 (엔진을 지우면 검색 화면도 바로 바뀐다).
    ..registerLazySingleton(() => EngineCubit(sl(), sl()));
}
