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

/// 홈 순위 · 분석 기간.
enum HomePeriod { week, month, all }

class TrackPlays extends Equatable {
  const TrackPlays(this.track, this.count);

  final Track track;
  final int count;

  @override
  List<Object?> get props => [track.id, count];
}

class ArtistPlays extends Equatable {
  const ArtistPlays(this.artist, this.count);

  /// 모르는 아티스트는 빈 문자열.
  final String artist;
  final int count;

  @override
  List<Object?> get props => [artist, count];
}

class GenrePlays extends Equatable {
  const GenrePlays(this.genre, this.count);

  final String genre;
  final int count;

  @override
  List<Object?> get props => [genre, count];
}

/// 청취 분석 (상세 기능: 청취 분석).
class ListeningStats extends Equatable {
  const ListeningStats({
    this.plays = 0,
    this.uniqueTracks = 0,
    this.listened = Duration.zero,
    this.topArtists = const [],
    this.topGenres = const [],
  });

  final int plays;
  final int uniqueTracks;
  final Duration listened;
  final List<ArtistPlays> topArtists;

  /// 장르를 아는 곡만 센다 (장르가 빈 곡은 제외).
  final List<GenrePlays> topGenres;

  @override
  List<Object?> get props => [
    plays,
    uniqueTracks,
    listened,
    topArtists,
    topGenres,
  ];
}

/// 홈 화면에 필요한 것 전부.
class HomeSummary extends Equatable {
  const HomeSummary({
    this.todayListened = Duration.zero,
    this.todayPlays = 0,
    this.topTracks = const [],
    this.stats = const ListeningStats(),
    this.recommendations = const [],
    this.recent = const [],
    this.libraryEmpty = true,
  });

  /// 오늘(기기 시간 0시부터) 들은 시간. 기간 선택과 무관하다.
  /// 들은 시간이 기록되지 않은 재생은 곡 길이로 어림한다.
  final Duration todayListened;

  /// 오늘 재생한 횟수.
  final int todayPlays;

  /// 기간 안에서 많이 들은 곡 (많은 순).
  final List<TrackPlays> topTracks;
  final ListeningStats stats;

  /// 추천 곡 (기기 재생 기록 기반).
  final List<Track> recommendations;

  /// 최근에 들은 곡 (중복 없이, 최근 순).
  final List<Track> recent;
  final bool libraryEmpty;

  @override
  List<Object?> get props => [
    todayListened,
    todayPlays,
    topTracks,
    stats,
    recommendations,
    recent,
    libraryEmpty,
  ];
}
