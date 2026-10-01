import 'package:equatable/equatable.dart';

import '../../../library/domain/entities/track.dart';

/// 재생 한 번 (상세 기능: 재생 기록 저장).
class PlayRecord extends Equatable {
  const PlayRecord({
    required this.trackId,
    required this.playedAt,
    this.listened = Duration.zero,
  });

  final String trackId;
  final DateTime playedAt;

  /// 실제로 들은 시간. 재생 엔진이 붙기 전에는 0.
  final Duration listened;

  @override
  List<Object?> get props => [trackId, playedAt, listened];
}

class TrackPlays extends Equatable {
  const TrackPlays(this.track, this.count);

  final Track track;
  final int count;

  @override
  List<Object?> get props => [track.id, count];
}

/// 아티스트별 재생. [tracks]는 그 아티스트의 곡을 많이 들은 순으로 담는다.
class ArtistPlays extends Equatable {
  const ArtistPlays(this.artist, this.count, this.tracks);

  /// 모르는 아티스트는 빈 문자열.
  final String artist;
  final int count;
  final List<Track> tracks;

  @override
  List<Object?> get props => [artist, count, tracks];
}

/// 장르별 재생. [tracks]는 그 장르의 곡을 많이 들은 순으로 담는다.
class GenrePlays extends Equatable {
  const GenrePlays(this.genre, this.count, this.tracks);

  final String genre;
  final int count;
  final List<Track> tracks;

  @override
  List<Object?> get props => [genre, count, tracks];
}

/// 하루치 청취 (꺾은선 그래프의 점 하나).
class DayListening extends Equatable {
  const DayListening(this.day, this.plays, this.listened);

  /// 그날 0시.
  final DateTime day;
  final int plays;
  final Duration listened;

  @override
  List<Object?> get props => [day, plays, listened];
}

/// 추천 재생목록의 종류.
enum RecommendedKind { artistMix, genreMix, rediscover, unheard, newest }

/// 추천 재생목록: 곡을 묶어 통째로 재생할 수 있다.
class RecommendedPlaylist extends Equatable {
  const RecommendedPlaylist(this.kind, this.tracks, {this.label = ''});

  final RecommendedKind kind;
  final List<Track> tracks;

  /// 아티스트 · 장르 이름 (그 밖의 종류는 빈 문자열).
  final String label;

  @override
  List<Object?> get props => [kind, label, tracks];
}

/// 전체 기간 청취 분석 (상세 기능: 청취 분석).
class ListeningStats extends Equatable {
  const ListeningStats({
    this.plays = 0,
    this.uniqueTracks = 0,
    this.listened = Duration.zero,
    this.daysListened = 0,
    this.topArtists = const [],
    this.topGenres = const [],
  });

  final int plays;
  final int uniqueTracks;
  final Duration listened;

  /// 한 번이라도 들은 날 수.
  final int daysListened;
  final List<ArtistPlays> topArtists;

  /// 장르를 아는 곡만 센다 (장르가 빈 곡은 제외).
  final List<GenrePlays> topGenres;

  @override
  List<Object?> get props => [
    plays,
    uniqueTracks,
    listened,
    daysListened,
    topArtists,
    topGenres,
  ];
}

/// 홈 화면에 필요한 것 전부.
class HomeSummary extends Equatable {
  const HomeSummary({
    this.todayListened = Duration.zero,
    this.todayPlays = 0,
    this.recent = const [],
    this.days = const [],
    this.topTracks = const [],
    this.stats = const ListeningStats(),
    this.recommendedPlaylists = const [],
    this.libraryEmpty = true,
  });

  /// 오늘(기기 시간 0시부터) 들은 시간.
  /// 들은 시간이 기록되지 않은 재생은 곡 길이로 어림한다.
  final Duration todayListened;

  /// 오늘 재생한 횟수.
  final int todayPlays;

  /// 최근에 들은 곡 (중복 없이, 최근 순).
  final List<Track> recent;

  /// 들은 기록이 있는 날들 (날짜 오름차순). 그래프는 [range]로 자른다.
  final List<DayListening> days;

  /// 가장 많이 들은 곡 (많은 순, 최대 100곡).
  final List<TrackPlays> topTracks;

  /// 전체 기간 통계 · 아티스트 · 장르 순위.
  final ListeningStats stats;

  /// 추천 재생목록 (기기 재생 기록 기반).
  final List<RecommendedPlaylist> recommendedPlaylists;
  final bool libraryEmpty;

  /// [from]~[to] 날짜(양 끝 포함)의 하루치 목록. 들은 기록이 없는 날은 0으로 채운다.
  List<DayListening> range(DateTime from, DateTime to) {
    final byDay = {for (final d in days) d.day: d};
    final out = <DayListening>[];
    for (
      var d = DateTime(from.year, from.month, from.day);
      !d.isAfter(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      out.add(byDay[d] ?? DayListening(d, 0, Duration.zero));
    }
    return out;
  }

  @override
  List<Object?> get props => [
    todayListened,
    todayPlays,
    recent,
    days,
    topTracks,
    stats,
    recommendedPlaylists,
    libraryEmpty,
  ];
}
