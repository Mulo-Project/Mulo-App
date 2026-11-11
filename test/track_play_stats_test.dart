import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/home/domain/usecases/home_usecases.dart';

import 'helpers/fakes.dart';

void main() {
  test('곡 하나의 재생 횟수 · 들은 시간 · 마지막 재생을 모은다', () async {
    final history = MemoryPlayHistory([
      PlayRecord(
        trackId: 'a',
        playedAt: DateTime(2026, 11, 1),
        listened: const Duration(minutes: 3),
      ),
      PlayRecord(
        trackId: 'a',
        playedAt: DateTime(2026, 11, 5),
        listened: const Duration(minutes: 2),
      ),
      PlayRecord(trackId: 'b', playedAt: DateTime(2026, 11, 9)),
    ]);
    final stats = await GetTrackPlayStats(history)('a');
    expect(stats.count, 2);
    expect(stats.listened, const Duration(minutes: 5));
    expect(stats.lastAt, DateTime(2026, 11, 5));
    expect((await GetTrackPlayStats(history)('none')).count, 0);
  });
}
