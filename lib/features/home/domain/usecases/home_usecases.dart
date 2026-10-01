import 'dart:async';

import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../entities/home_summary.dart';
import '../repositories/play_history_repository.dart';

/// 곡 재생을 기록한다 (상세 기능: 재생 기록 저장).
class RecordPlay implements UseCase<void, PlayRecord> {
  const RecordPlay(this._repo);

  final PlayHistoryRepository _repo;

  @override
  Future<void> call(PlayRecord record) => _repo.recordPlay(record);
}

class HomeSummaryParams {
  const HomeSummaryParams(this.period, {this.month, this.now});

  final HomePeriod period;

  /// "이번 달" 기간에서 볼 달 (그 달의 아무 날). 없으면 지금이 속한 달.
  final DateTime? month;

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
          period: p.period,
          month: p.month,
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

/// 홈 요약 계산 (순수 함수).
///
/// 기간: 이번 주 = 오늘을 포함한 최근 7일, 이번 달 = [month]가 속한 달 전체, 전체 = 기록 전부.
HomeSummary buildHomeSummary({
  required List<Track> tracks,
  required List<PlayRecord> plays,
  required HomePeriod period,
  required DateTime now,
  DateTime? month,
  int topCount = 100,
  int rankCount = 5,
  int recentCount = 8,
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
  final picked = month ?? now;
  final monthStart = DateTime(picked.year, picked.month);
  final monthEnd = DateTime(picked.year, picked.month + 1);

  final (DateTime? from, DateTime? until) = switch (period) {
    HomePeriod.week => (today.subtract(const Duration(days: 6)), null),
    HomePeriod.month => (monthStart, monthEnd),
    HomePeriod.all => (null, null),
  };
  final inPeriod = [
    for (final pl in known)
      if ((from == null || !pl.playedAt.isBefore(from)) &&
          (until == null || pl.playedAt.isBefore(until)))
        pl,
  ];

  // 많이 들은 곡
  final trackCounts = <String, int>{};
  for (final pl in inPeriod) {
    trackCounts[pl.trackId] = (trackCounts[pl.trackId] ?? 0) + 1;
  }
  final topTracks =
      [for (final e in trackCounts.entries) TrackPlays(byId[e.key]!, e.value)]
        ..sort((a, b) {
          final c = b.count.compareTo(a.count);
          return c != 0 ? c : a.track.title.compareTo(b.track.title);
        });

  // 아티스트 · 장르 · 앨범 순위 (장르 · 앨범은 모르는 곡을 뺀다)
  List<MapEntry<String, int>> rank(
    String Function(Track) key, {
    bool skipEmpty = false,
  }) {
    final counts = <String, int>{};
    for (final pl in inPeriod) {
      final k = key(byId[pl.trackId]!);
      if (skipEmpty && k.isEmpty) continue;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  final topArtists = rank((t) => t.artist);
  final stats = ListeningStats(
    plays: inPeriod.length,
    uniqueTracks: trackCounts.length,
    listened: inPeriod.fold(Duration.zero, (sum, pl) => sum + heard(pl)),
    topArtists: [
      for (final e in topArtists.take(rankCount)) ArtistPlays(e.key, e.value),
    ],
    topGenres: [
      for (final e in rank((t) => t.genre, skipEmpty: true).take(rankCount))
        GenrePlays(e.key, e.value),
    ],
    topAlbums: [
      for (final e in rank((t) => t.album, skipEmpty: true).take(rankCount))
        AlbumPlays(e.key, e.value),
    ],
    daysListened: {for (final pl in inPeriod) _dayOf(pl.playedAt)}.length,
  );

  // 날짜별 (꺾은선 그래프). 이번 달은 오늘까지만 그린다.
  final daily = <DayListening>[];
  if (from != null) {
    final last = period == HomePeriod.week
        ? today
        : (monthEnd.isAfter(today)
              ? today
              : monthEnd.subtract(const Duration(days: 1)));
    final dayPlays = <DateTime, int>{};
    final dayTime = <DateTime, Duration>{};
    for (final pl in inPeriod) {
      final d = _dayOf(pl.playedAt);
      dayPlays[d] = (dayPlays[d] ?? 0) + 1;
      dayTime[d] = (dayTime[d] ?? Duration.zero) + heard(pl);
    }
    for (
      var d = from;
      !d.isAfter(last);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      daily.add(DayListening(d, dayPlays[d] ?? 0, dayTime[d] ?? Duration.zero));
    }
  }

  // 최근 재생 (중복 없이)
  final recent = <Track>[];
  final seen = <String>{};
  for (final pl in known) {
    if (seen.add(pl.trackId)) recent.add(byId[pl.trackId]!);
    if (recent.length == recentCount) break;
  }

  // 추천 재생목록: 많이 들은 아티스트 · 장르의 덜 들은 곡 묶음, 안 들어본 곡, 새로 담은 곡.
  final allCounts = <String, int>{};
  final artistCounts = <String, int>{};
  final genreCounts = <String, int>{};
  for (final pl in known) {
    final t = byId[pl.trackId]!;
    allCounts[t.id] = (allCounts[t.id] ?? 0) + 1;
    if (t.artist.isNotEmpty) {
      artistCounts[t.artist] = (artistCounts[t.artist] ?? 0) + 1;
    }
    if (t.genre.isNotEmpty) {
      genreCounts[t.genre] = (genreCounts[t.genre] ?? 0) + 1;
    }
  }
  List<String> mostPlayed(Map<String, int> counts) =>
      (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .map((e) => e.key)
          .toList();

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
  for (final artist in mostPlayed(artistCounts).take(2)) {
    final list = leastHeardFirst(tracks.where((t) => t.artist == artist));
    if (list.length >= 2) {
      playlists.add(
        RecommendedPlaylist(RecommendedKind.artistMix, list, label: artist),
      );
    }
  }
  for (final genre in mostPlayed(genreCounts).take(1)) {
    final list = leastHeardFirst(tracks.where((t) => t.genre == genre));
    if (list.length >= 2) {
      playlists.add(
        RecommendedPlaylist(RecommendedKind.genreMix, list, label: genre),
      );
    }
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

  // 오늘 들은 시간
  final todayPlays = [
    for (final pl in known)
      if (!pl.playedAt.isBefore(today) && !pl.playedAt.isAfter(now)) pl,
  ];

  return HomeSummary(
    todayListened: todayPlays.fold(Duration.zero, (sum, pl) => sum + heard(pl)),
    todayPlays: todayPlays.length,
    topTracks: topTracks.take(topCount).toList(),
    stats: stats,
    daily: daily,
    recommendedPlaylists: playlists,
    recent: recent,
    libraryEmpty: tracks.isEmpty,
  );
}
