import 'package:get_it/get_it.dart';

import 'presentation/bloc/now_playing_cubit.dart';

void registerPlayer(GetIt sl) {
  sl.registerFactory(NowPlayingCubit.new);
}
