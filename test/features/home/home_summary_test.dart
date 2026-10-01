import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/home/domain/usecases/home_usecases.dart';
import 'package:music_download_play_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(
  String id,
  String artist,
  int day, {
  String genre = '',
  Duration duration = const Duration(minutes: 3),
}) => Track(
  id: id,
  title: 'Song $id',
  artist: artist,
  album: '',
  genre: genre,
  duration: duration,
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

  HomeSummary build(List<PlayRecord> plays, [List<Track>? library]) =>
      buildHomeSummary(tracks: library ?? tracks, plays: plays, now: now);

  test('오늘 들은 시간은 오늘 0시 이후 재생만 더하고, 기록이 없으면 곡 길이로 어림한다', () {
    final s = build([
      _p('a', DateTime(2026, 10, 1, 9)), // 곡 길이 3분으로 어림
      PlayRecord(
        trackId: 'b',
        playedAt: DateTime(2026, 10, 1, 10),
        listened: const Duration(minutes: 1),
      ),
      _p('c', DateTime(2026, 9, 30, 23, 59)), // 어제
    ]);
    expect(s.todayListened, const Duration(minutes: 4));
    expect(s.todayPlays, 2);
  });

  test('많이 들은 곡은 전체 기간에서 많은 순, 100곡까지', () {
    final s = build([
      _p('a', now.subtract(const Duration(days: 1))),
      _p('a', now.subtract(const Duration(days: 40))),
      _p('c', now.subtract(const Duration(days: 3))),
    ]);
    expect(s.topTracks.map((e) => (e.track.id, e.count)), [('a', 2), ('c', 1)]);
    expect(s.stats.plays, 3);
    expect(s.stats.uniqueTracks, 2);

    final many = [for (var i = 0; i < 120; i++) _t('t$i', 'x', 1)];
    final big = build([for (final t in many) _p(t.id, now)], many);
    expect(big.topTracks.length, 100);
  });

  test('최근 재생은 중복 없이 최근 순', () {
    final s = build([
      _p('c', now),
      _p('a', now.subtract(const Duration(hours: 1))),
      _p('c', now.subtract(const Duration(hours: 2))),
    ]);
    expect(s.recent.map((t) => t.id), ['c', 'a']);
  });

  test('보관함에 없는 곡의 기록은 무시한다', () {
    final s = build([_p('zzz', now)]);
    expect(s.stats.plays, 0);
    expect(s.recent, isEmpty);
  });

  test('날짜별: range는 기록 없는 날을 0으로 채우고 양 끝 날짜를 포함한다', () {
    final s = build([
      _p('a', DateTime(2026, 10, 1, 9)),
      _p('a', DateTime(2026, 10, 1, 10)),
      _p('b', DateTime(2026, 9, 28, 10)),
      _p('c', DateTime(2026, 9, 24, 10)), // 범위 밖
    ]);
    final week = s.range(DateTime(2026, 9, 25), DateTime(2026, 10, 1));
    expect(week.length, 7);
    expect(week.first.day, DateTime(2026, 9, 25));
    expect(week.last.plays, 2);
    expect(week.last.listened, const Duration(minutes: 6));
    expect(week.where((d) => d.plays == 0).length, 5);
    expect(s.stats.daysListened, 3);
  });

  test('전체 통계: 총 재생 수 · 시간 · 들은 날', () {
    final s = build([
      _p('a', DateTime(2026, 8, 1, 9)),
      _p('a', DateTime(2026, 8, 1, 10)),
      _p('b', DateTime(2026, 9, 1, 9)),
    ]);
    expect(s.stats.plays, 3);
    expect(s.stats.listened, const Duration(minutes: 9));
    expect(s.stats.daysListened, 2);
  });

  test('아티스트 · 장르 순위: 곡은 많이 들은 순, 장르를 모르는 곡은 장르에서 뺀다', () {
    final lib = [
      _t('a', 'Neon', 1, genre: '록'),
      _t('b', 'Neon', 2, genre: '발라드'),
      _t('c', 'Coral', 3),
    ];
    final s = build([
      _p('a', now),
      _p('b', now),
      _p('b', now),
      _p('c', now),
    ], lib);
    expect(s.stats.topArtists.map((a) => (a.artist, a.count)), [
      ('Neon', 3),
      ('Coral', 1),
    ]);
    expect(s.stats.topArtists.first.tracks.map((t) => t.id), ['b', 'a']);
    expect(s.stats.topGenres.map((g) => (g.genre, g.count)), [
      ('발라드', 2),
      ('록', 1),
    ]);
  });

  test('추천 재생목록: 많이 들은 아티스트의 덜 들은 곡 묶음이 먼저', () {
    final s = build([
      _p('a', now),
      _p('a', now.subtract(const Duration(hours: 1))),
    ]);
    final mix = s.recommendedPlaylists.first;
    expect(mix.kind, RecommendedKind.artistMix);
    expect(mix.label, 'Neon');
    expect(mix.tracks.map((t) => t.id), ['b', 'a']); // 덜 들은 곡이 먼저
    expect(
      s.recommendedPlaylists.map((p) => p.kind),
      containsAll([RecommendedKind.unheard, RecommendedKind.newest]),
    );
  });

  test('HomeBloc: 요약과 가입일을 읽는다', () async {
    final bloc = HomeBloc(
      WatchHomeSummary(
        FakeLibraryRepository(tracks),
        MemoryPlayHistory([_p('a', DateTime.now())]),
      ),
      GetJoinDate(MemoryJoinDate(DateTime(2026, 7, 15))),
    );
    addTearDown(bloc.close);
    bloc.add(const HomeStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.loaded, isTrue);
    expect(bloc.state.summary.stats.plays, 1);
    expect(bloc.state.joinedAt, DateTime(2026, 7, 15));
  });
}
