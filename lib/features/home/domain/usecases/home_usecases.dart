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
  const HomeSummaryParams(this.period, {this.now});

  final HomePeriod period;

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

/// 홈 요약 계산 (순수 함수).
HomeSummary buildHomeSummary({
  required List<Track> tracks,
  required List<PlayRecord> plays,
  required HomePeriod period,
  required DateTime now,
  int topCount = 5,
  int recommendCount = 8,
  int recentCount = 8,
}) {
  final byId = {for (final t in tracks) t.id: t};
  final known = [
    for (final pl in plays)
      if (byId.containsKey(pl.trackId)) pl,
  ];

  final since = switch (period) {
    HomePeriod.week => now.subtract(const Duration(days: 7)),
    HomePeriod.month => now.subtract(const Duration(days: 30)),
    HomePeriod.all => null,
  };
  final inPeriod = [
    for (final pl in known)
      if (since == null || !pl.playedAt.isBefore(since)) pl,
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

  // 아티스트
  final artistCounts = <String, int>{};
  for (final pl in inPeriod) {
    final artist = byId[pl.trackId]!.artist;
    artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
  }
  final topArtists = [
    for (final e in artistCounts.entries) ArtistPlays(e.key, e.value),
  ]..sort((a, b) => b.count.compareTo(a.count));

  // 장르 (모르는 곡은 제외)
  final genreCounts = <String, int>{};
  for (final pl in inPeriod) {
    final genre = byId[pl.trackId]!.genre;
    if (genre.isNotEmpty) genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
  }
  final topGenres = [
    for (final e in genreCounts.entries) GenrePlays(e.key, e.value),
  ]..sort((a, b) => b.count.compareTo(a.count));

  final stats = ListeningStats(
    plays: inPeriod.length,
    uniqueTracks: trackCounts.length,
    listened: inPeriod.fold(Duration.zero, (sum, pl) => sum + pl.listened),
    topArtists: topArtists.take(3).toList(),
    topGenres: topGenres.take(3).toList(),
  );

  // 최근 재생 (중복 없이)
  final recent = <Track>[];
  final seen = <String>{};
  for (final pl in known) {
    if (seen.add(pl.trackId)) recent.add(byId[pl.trackId]!);
    if (recent.length == recentCount) break;
  }

  // 추천: 많이 들은 아티스트의 아직 덜 들은 곡 → 부족하면 최근 추가된 안 들어본 곡.
  final allCounts = <String, int>{};
  for (final pl in known) {
    allCounts[pl.trackId] = (allCounts[pl.trackId] ?? 0) + 1;
  }
  final favoriteArtists = [
    for (final a in topArtists)
      if (a.artist.isNotEmpty) a.artist,
  ];
  int artistRank(Track t) {
    final i = favoriteArtists.indexOf(t.artist);
    return i < 0 ? favoriteArtists.length : i;
  }

  final candidates =
      [
        for (final t in tracks)
          if ((allCounts[t.id] ?? 0) < 2) t,
      ]..sort((a, b) {
        final r = artistRank(a).compareTo(artistRank(b));
        if (r != 0) return r;
        final c = (allCounts[a.id] ?? 0).compareTo(allCounts[b.id] ?? 0);
        return c != 0 ? c : b.addedAt.compareTo(a.addedAt);
      });

  // 오늘 들은 시간: 기록된 시간이 없으면 곡 길이로 어림한다.
  final midnight = DateTime(now.year, now.month, now.day);
  final today = [
    for (final pl in known)
      if (!pl.playedAt.isBefore(midnight) && !pl.playedAt.isAfter(now)) pl,
  ];
  final todayListened = today.fold(Duration.zero, (sum, pl) {
    final heard = pl.listened > Duration.zero
        ? pl.listened
        : byId[pl.trackId]!.duration;
    return sum + heard;
  });

  return HomeSummary(
    todayListened: todayListened,
    todayPlays: today.length,
    topTracks: topTracks.take(topCount).toList(),
    stats: stats,
    recommendations: candidates.take(recommendCount).toList(),
    recent: recent,
    libraryEmpty: tracks.isEmpty,
  );
}
