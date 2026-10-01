import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/home/domain/usecases/home_usecases.dart';
import 'package:music_download_play_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String artist, int day, [String genre = '']) => Track(
  id: id,
  title: 'Song $id',
  artist: artist,
  album: '',
  genre: genre,
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

  test('오늘 들은 시간은 오늘 0시 이후 재생만 더하고, 기록이 없으면 곡 길이로 어림한다', () {
    final s = buildHomeSummary(
      tracks: tracks,
      plays: [
        _p('a', DateTime(2026, 10, 1, 9)), // 곡 길이 3분으로 어림
        PlayRecord(
          trackId: 'b',
          playedAt: DateTime(2026, 10, 1, 10),
          listened: const Duration(minutes: 1),
        ),
        _p('c', DateTime(2026, 9, 30, 23, 59)), // 어제
      ],
      period: HomePeriod.week,
      now: now,
    );
    expect(s.todayListened, const Duration(minutes: 4));
    expect(s.todayPlays, 2);
  });

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
    final mix = s.recommendedPlaylists.first;
    expect(mix.kind, RecommendedKind.artistMix);
    expect(mix.label, 'Neon');
    expect(mix.tracks.map((t) => t.id), ['b', 'a']); // 덜 들은 곡이 먼저
    expect(
      s.recommendedPlaylists.map((p) => p.kind),
      containsAll([RecommendedKind.unheard, RecommendedKind.newest]),
    );
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

  test('HomeBloc: 기간 · 달을 바꾸면 다시 계산한다', () async {
    final today = DateTime.now();
    final prev = DateTime(today.year, today.month - 1);
    final bloc = HomeBloc(
      WatchHomeSummary(
        FakeLibraryRepository(tracks),
        MemoryPlayHistory([_p('a', DateTime(prev.year, prev.month, 15, 12))]),
      ),
    );
    addTearDown(bloc.close);
    bloc.add(const HomeStarted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.summary.stats.plays, 0); // 이번 주에는 없음
    bloc.add(const HomePeriodChanged(HomePeriod.month));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.period, HomePeriod.month);
    expect(bloc.state.summary.stats.plays, 0); // 이번 달에는 없음
    bloc.add(HomeMonthChanged(prev));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.summary.stats.plays, 1);
  });

  test('장르 통계: 장르를 아는 곡만 세고 많은 순', () {
    final withGenre = [
      _t('a', 'Neon', 1, '록'),
      _t('b', 'Neon', 2, '발라드'),
      _t('c', 'Coral', 3), // 장르 모름
    ];
    final s = buildHomeSummary(
      tracks: withGenre,
      plays: [
        _p('a', now.subtract(const Duration(days: 1))),
        _p('b', now.subtract(const Duration(days: 1))),
        _p('b', now.subtract(const Duration(days: 2))),
        _p('c', now.subtract(const Duration(days: 2))),
        _p('a', now.subtract(const Duration(days: 20))), // 이번 주 밖
      ],
      period: HomePeriod.week,
      now: now,
    );
    expect(s.stats.topGenres.map((g) => (g.genre, g.count)), [
      ('발라드', 2),
      ('록', 1),
    ]);
  });

  test('이번 주는 오늘 포함 7일치 일별 데이터를 만든다', () {
    final s = buildHomeSummary(
      tracks: tracks,
      plays: [
        _p('a', DateTime(2026, 10, 1, 9)),
        _p('a', DateTime(2026, 10, 1, 10)),
        _p('b', DateTime(2026, 9, 28, 10)),
        _p('c', DateTime(2026, 9, 24, 10)), // 7일 밖
      ],
      period: HomePeriod.week,
      now: now,
    );
    expect(s.daily.length, 7);
    expect(s.daily.first.day, DateTime(2026, 9, 25));
    expect(s.daily.last.day, DateTime(2026, 10, 1));
    expect(s.daily.last.plays, 2);
    expect(s.daily.last.listened, const Duration(minutes: 6));
    expect(s.stats.daysListened, 2);
  });

  test('이번 달은 고른 달 전체를 본다 (지난 달은 그 달 마지막 날까지)', () {
    final plays = [
      _p('a', DateTime(2026, 9, 3, 9)),
      _p('b', DateTime(2026, 9, 30, 23)),
      _p('c', DateTime(2026, 10, 1, 9)),
    ];
    final s = buildHomeSummary(
      tracks: tracks,
      plays: plays,
      period: HomePeriod.month,
      month: DateTime(2026, 9),
      now: now,
    );
    expect(s.stats.plays, 2);
    expect(s.daily.length, 30);
    final thisMonth = buildHomeSummary(
      tracks: tracks,
      plays: plays,
      period: HomePeriod.month,
      now: now,
    );
    expect(thisMonth.stats.plays, 1);
    expect(thisMonth.daily.length, 1); // 오늘(1일)까지만
  });

  test('전체 기간: 일별 데이터는 없고 들은 날 · 총 시간을 센다', () {
    final s = buildHomeSummary(
      tracks: tracks,
      plays: [
        _p('a', DateTime(2026, 8, 1, 9)),
        _p('a', DateTime(2026, 8, 1, 10)),
        _p('b', DateTime(2026, 9, 1, 9)),
      ],
      period: HomePeriod.all,
      now: now,
    );
    expect(s.daily, isEmpty);
    expect(s.stats.daysListened, 2);
    expect(s.stats.listened, const Duration(minutes: 9));
  });

  test('앨범 순위: 앨범을 아는 곡만 센다, 많이 들은 곡은 100곡까지', () {
    final withAlbum = [
      for (var i = 0; i < 120; i++)
        Track(
          id: 't$i',
          title: 'T$i',
          artist: 'x',
          album: i == 0 ? '' : 'Album ${i % 2}',
          duration: const Duration(minutes: 3),
          uri: 'u:$i',
          addedAt: DateTime(2026, 9, 1),
        ),
    ];
    final s = buildHomeSummary(
      tracks: withAlbum,
      plays: [for (final t in withAlbum) _p(t.id, now)],
      period: HomePeriod.all,
      now: now,
    );
    expect(s.stats.topAlbums.length, 2);
    expect(s.stats.topAlbums.first.album, 'Album 1');
    expect(s.topTracks.length, 100);
  });
}
