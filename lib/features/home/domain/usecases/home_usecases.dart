import 'dart:async';

import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../entities/home_summary.dart';
import '../repositories/join_date_repository.dart';
import '../repositories/play_history_repository.dart';

/// 곡 재생을 기록한다 (상세 기능: 재생 기록 저장).
class RecordPlay implements UseCase<void, PlayRecord> {
  const RecordPlay(this._repo);

  final PlayHistoryRepository _repo;

  @override
  Future<void> call(PlayRecord record) => _repo.recordPlay(record);
}

class HomeSummaryParams {
  const HomeSummaryParams({this.now});

  /// 기준 시각 (테스트용). 없으면 지금.
  final DateTime Function()? now;
}

/// 홈 요약: 보관함 · 재생 기록이 바뀔 때마다 다시 계산한다.
class WatchHomeSummary
    implements StreamUseCase<HomeSummary, HomeSummaryParams> {
  const WatchHomeSummary(this._library, this._history);

  final LibraryRepository _library;
  final PlayHistoryRepository _history;

  @override
  Stream<HomeSummary> call(HomeSummaryParams p) {
    late StreamController<HomeSummary> out;
    List<Track>? tracks;
    List<PlayRecord>? plays;
    final subs = <StreamSubscription<Object?>>[];

    void emit() {
      if (tracks == null || plays == null) return;
      out.add(
        buildHomeSummary(
          tracks: tracks!,
          plays: plays!,
          now: (p.now ?? DateTime.now)(),
        ),
      );
    }

    out = StreamController<HomeSummary>(
      onListen: () {
        subs
          ..add(
            _library.watchTracks().listen((t) {
              tracks = t;
              emit();
            }, onError: out.addError),
          )
          ..add(
            _history.watchPlays().listen((pl) {
              plays = pl;
              emit();
            }, onError: out.addError),
          );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// 홈 요약 계산 (순수 함수). 순위 · 통계는 전체 기간 기준이고,
/// 기간별(주 · 월) 그래프는 [HomeSummary.days]를 [HomeSummary.range]로 잘라 그린다.
HomeSummary buildHomeSummary({
  required List<Track> tracks,
  required List<PlayRecord> plays,
  required DateTime now,
  int topCount = 100,
  int rankCount = 10,
  int recentCount = 10,
  int playlistSize = 30,
}) {
  final byId = {for (final t in tracks) t.id: t};
  final known = [
    for (final pl in plays)
      if (byId.containsKey(pl.trackId)) pl,
  ];

  /// 들은 시간: 기록된 시간이 없으면 곡 길이로 어림한다.
  Duration heard(PlayRecord pl) =>
      pl.listened > Duration.zero ? pl.listened : byId[pl.trackId]!.duration;

  final today = _dayOf(now);

  // 곡별 재생 횟수 (많이 들은 곡)
  final allCounts = <String, int>{};
  for (final pl in known) {
    allCounts[pl.trackId] = (allCounts[pl.trackId] ?? 0) + 1;
  }
  final topTracks =
      [for (final e in allCounts.entries) TrackPlays(byId[e.key]!, e.value)]
        ..sort((a, b) {
          final c = b.count.compareTo(a.count);
          return c != 0 ? c : a.track.title.compareTo(b.track.title);
        });

  // 아티스트 · 장르 순위: 곡 목록은 그 곡을 많이 들은 순
  List<(String, int, List<Track>)> group(
    String Function(Track) key, {
    bool skipEmpty = false,
  }) {
    final counts = <String, int>{};
    final members = <String, List<TrackPlays>>{};
    for (final tp in topTracks) {
      final k = key(tp.track);
      if (skipEmpty && k.isEmpty) continue;
      counts[k] = (counts[k] ?? 0) + tp.count;
      (members[k] ??= []).add(tp);
    }
    final keys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [
      for (final k in keys.take(rankCount))
        (k, counts[k]!, [for (final tp in members[k]!) tp.track]),
    ];
  }

  final topArtists = group((t) => t.artist);
  final topGenres = group((t) => t.genre, skipEmpty: true);

  // 날짜별
  final dayPlays = <DateTime, int>{};
  final dayTime = <DateTime, Duration>{};
  for (final pl in known) {
    final d = _dayOf(pl.playedAt);
    dayPlays[d] = (dayPlays[d] ?? 0) + 1;
    dayTime[d] = (dayTime[d] ?? Duration.zero) + heard(pl);
  }
  final days = [
    for (final d in dayPlays.keys.toList()..sort())
      DayListening(d, dayPlays[d]!, dayTime[d]!),
  ];

  final stats = ListeningStats(
    plays: known.length,
    uniqueTracks: allCounts.length,
    listened: known.fold(Duration.zero, (sum, pl) => sum + heard(pl)),
    daysListened: days.length,
    topArtists: [for (final (a, c, t) in topArtists) ArtistPlays(a, c, t)],
    topGenres: [for (final (g, c, t) in topGenres) GenrePlays(g, c, t)],
  );

  // 최근 재생 (중복 없이)
  final recent = <Track>[];
  final seen = <String>{};
  for (final pl in known) {
    if (seen.add(pl.trackId)) recent.add(byId[pl.trackId]!);
    if (recent.length == recentCount) break;
  }

  // 추천 재생목록: 많이 들은 아티스트 · 장르의 덜 들은 곡 묶음, 안 들어본 곡, 새로 담은 곡.
  List<Track> leastHeardFirst(Iterable<Track> list) {
    final sorted = [...list]
      ..sort((a, b) {
        final c = (allCounts[a.id] ?? 0).compareTo(allCounts[b.id] ?? 0);
        return c != 0 ? c : b.addedAt.compareTo(a.addedAt);
      });
    return sorted.take(playlistSize).toList();
  }

  final newestFirst = [...tracks]
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  final playlists = <RecommendedPlaylist>[];
  for (final (artist, _, _)
      in topArtists.where((a) => a.$1.isNotEmpty).take(3)) {
    final list = leastHeardFirst(tracks.where((t) => t.artist == artist));
    if (list.length >= 2) {
      playlists.add(
        RecommendedPlaylist(RecommendedKind.artistMix, list, label: artist),
      );
    }
  }
  for (final (genre, _, _) in topGenres.take(2)) {
    final list = leastHeardFirst(tracks.where((t) => t.genre == genre));
    if (list.length >= 2) {
      playlists.add(
        RecommendedPlaylist(RecommendedKind.genreMix, list, label: genre),
      );
    }
  }
  // 오랜만에: 들은 적은 있지만 마지막으로 들은 지 가장 오래된 곡.
  final lastPlayed = <String, DateTime>{};
  for (final pl in known) {
    lastPlayed.putIfAbsent(pl.trackId, () => pl.playedAt);
  }
  final rediscover = [for (final id in lastPlayed.keys) byId[id]!]
    ..sort((a, b) => lastPlayed[a.id]!.compareTo(lastPlayed[b.id]!));
  if (rediscover.length >= 2) {
    playlists.add(
      RecommendedPlaylist(
        RecommendedKind.rediscover,
        rediscover.take(playlistSize).toList(),
      ),
    );
  }
  final unheard = [
    for (final t in newestFirst)
      if (!allCounts.containsKey(t.id)) t,
  ].take(playlistSize).toList();
  if (unheard.isNotEmpty) {
    playlists.add(RecommendedPlaylist(RecommendedKind.unheard, unheard));
  }
  if (newestFirst.isNotEmpty) {
    playlists.add(
      RecommendedPlaylist(
        RecommendedKind.newest,
        newestFirst.take(playlistSize).toList(),
      ),
    );
  }

  // 오늘 들은 횟수 · 시간
  final todays = [
    for (final pl in known)
      if (!pl.playedAt.isBefore(today) && !pl.playedAt.isAfter(now)) pl,
  ];

  return HomeSummary(
    todayListened: todays.fold(Duration.zero, (sum, pl) => sum + heard(pl)),
    todayPlays: todays.length,
    recent: recent,
    days: days,
    topTracks: topTracks.take(topCount).toList(),
    stats: stats,
    recommendedPlaylists: playlists,
    libraryEmpty: tracks.isEmpty,
  );
}

/// 앱을 처음 쓴 날 (재생 기록 달력의 시작).
class GetJoinDate implements UseCase<DateTime, NoParams> {
  const GetJoinDate(this._repo);

  final JoinDateRepository _repo;

  @override
  Future<DateTime> call(NoParams params) => _repo.joinedAt();
}
