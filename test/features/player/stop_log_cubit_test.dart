import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/player/domain/repositories/stop_log_repository.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/stop_log_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  setUp(setUpTestDependencies);

  test('기록을 최신이 앞으로 불러오고, 지우면 비운다', () async {
    (sl<StopLogRepository>() as MemoryStopLogRepository).lines = [
      '11-04 10:00:00 pause: a',
      '11-04 11:00:00 error: b',
    ];
    final cubit = sl<StopLogCubit>();
    expect(cubit.state, isNull);

    await cubit.load();
    expect(cubit.state, ['11-04 11:00:00 error: b', '11-04 10:00:00 pause: a']);

    await cubit.clear();
    expect(cubit.state, isEmpty);
    await cubit.close();
  });
}
