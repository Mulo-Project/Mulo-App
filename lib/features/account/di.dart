import 'package:get_it/get_it.dart';

import 'data/repositories/google_account_repository.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/usecases/account_usecases.dart';
import 'presentation/bloc/account_cubit.dart';

/// 구글 계정 로그인 · 내 유튜브 재생목록 의존성. 테스트는 [AccountRepository]만 바꾼다.
void registerAccount(GetIt sl) {
  sl
    ..registerLazySingleton<AccountRepository>(GoogleAccountRepository.new)
    ..registerFactory(() => GetAccountSupport(sl()))
    ..registerFactory(() => RestoreAccount(sl()))
    ..registerFactory(() => SignInAccount(sl()))
    ..registerFactory(() => SignOutAccount(sl()))
    ..registerFactory(() => FetchMyPlaylists(sl()))
    ..registerFactory(() => AccountCubit(sl(), sl(), sl(), sl()));
}
