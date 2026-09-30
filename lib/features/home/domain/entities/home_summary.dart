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

/// 청취 분석 (상세 기능: 청취 분석).
class ListeningStats extends Equatable {
  const ListeningStats({
    this.plays = 0,
    this.uniqueTracks = 0,
    this.listened = Duration.zero,
    this.topArtists = const [],
  });

  final int plays;
  final int uniqueTracks;
  final Duration listened;
  final List<ArtistPlays> topArtists;

  @override
  List<Object?> get props => [plays, uniqueTracks, listened, topArtists];
}

/// 홈 화면에 필요한 것 전부.
class HomeSummary extends Equatable {
  const HomeSummary({
    this.topTracks = const [],
    this.stats = const ListeningStats(),
    this.recommendations = const [],
    this.recent = const [],
    this.libraryEmpty = true,
  });

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
    topTracks,
    stats,
    recommendations,
    recent,
    libraryEmpty,
  ];
}
