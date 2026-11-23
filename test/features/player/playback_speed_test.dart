import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/player/domain/entities/playback_speed.dart';
import 'package:music_download_play_app/features/player/domain/usecases/playback_speed_usecases.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/playback_speed_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  test('저장된 속도를 불러오고, 바꾸면 저장한다', () async {
    final repo = MemoryPlaybackSpeedRepository()..value = 1.5;
    final cubit = PlaybackSpeedCubit(
      loadSpeed: LoadPlaybackSpeed(repo),
      saveSpeed: SavePlaybackSpeed(repo),
    );
    expect(cubit.state, PlaybackSpeed.normal);
    await cubit.load();
    expect(cubit.state, 1.5);
    await cubit.set(0.75);
    expect(cubit.state, 0.75);
    expect(repo.value, 0.75);
    await cubit.close();
  });

  test('목록에 없는 속도는 보통으로 돌린다', () {
    expect(PlaybackSpeed.sanitize(1.25), 1.25);
    expect(PlaybackSpeed.sanitize(3), PlaybackSpeed.normal);
    expect(PlaybackSpeed.sanitize(null), PlaybackSpeed.normal);
  });
}
