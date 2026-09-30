import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/home/domain/usecases/home_usecases.dart';
import 'package:music_download_play_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String artist, int day) => Track(
  id: id,
  title: 'Song $id',
  artist: artist,
  album: '',
  duration: const Duration(minutes: 3),
  uri: 'u:$id',
  addedAt: DateTime(2026, 9, day),
);

PlayRecord _p(String id, DateTime at) => PlayRecord(trackId: id, playedAt: at);

void main() {
  final now = DateTime(2026, 10, 1, 12);
  final tracks = [
    _t('a', 'Neon', 1),
    _t('b', 'Neon', 2),
    _t('c', 'Coral', 3),
    _t('d', '', 4),
  ];

  test('기간 안의 재생만 세고 많은 순으로 정렬한다', () {
    final s = buildHomeSummary(
      tracks: tracks,
      plays: [
        _p('a', now.subtract(const Duration(days: 1))),
        _p('a', now.subtract(const Duration(days: 2))),
        _p('c', now.subtract(const Duration(days: 3))),
        _p('c', now.subtract(const Duration(days: 20))), // 이번 주 밖
      ],
      period: HomePeriod.week,
      now: now,
    );
    expect(s.topTracks.map((e) => (e.track.id, e.count)), [('a', 2), ('c', 1)]);
    expect(s.stats.plays, 3);
    expect(s.stats.uniqueTracks, 2);
    expect(s.stats.topArtists.first.artist, 'Neon');
  });

  test('최근 재생은 중복 없이 최근 순', () {
    final s = buildHomeSummary(
      tracks: tracks,
      plays: [
        _p('c', now),
        _p('a', now.subtract(const Duration(hours: 1))),
        _p('c', now.subtract(const Duration(hours: 2))),
      ],
      period: HomePeriod.all,
      now: now,
    );
    expect(s.recent.map((t) => t.id), ['c', 'a']);
  });

  test('추천: 많이 들은 아티스트의 덜 들은 곡이 먼저', () {
    final s = buildHomeSummary(
      tracks: tracks,
      plays: [_p('a', now), _p('a', now.subtract(const Duration(hours: 1)))],
      period: HomePeriod.all,
      now: now,
    );
    expect(s.recommendations.first.id, 'b'); // Neon의 안 들은 곡
    expect(s.recommendations.map((t) => t.id), isNot(contains('a')));
  });

  test('보관함에 없는 곡의 기록은 무시한다', () {
    final s = buildHomeSummary(
      tracks: tracks,
      plays: [_p('zzz', now)],
      period: HomePeriod.all,
      now: now,
    );
    expect(s.stats.plays, 0);
    expect(s.recent, isEmpty);
  });

  test('HomeBloc: 기간을 바꾸면 다시 계산한다', () async {
    final bloc = HomeBloc(
      WatchHomeSummary(
        FakeLibraryRepository(tracks),
        MemoryPlayHistory([
          _p('a', DateTime.now().subtract(const Duration(days: 20))),
        ]),
      ),
    );
    addTearDown(bloc.close);
    bloc.add(const HomeStarted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.summary.stats.plays, 0); // 이번 주에는 없음
    bloc.add(const HomePeriodChanged(HomePeriod.month));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.period, HomePeriod.month);
    expect(bloc.state.summary.stats.plays, 1);
  });
}
