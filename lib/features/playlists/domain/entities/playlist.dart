import 'package:equatable/equatable.dart';

/// 재생목록 카드 요약에 보여 줄 곡 하나 (많이 들은 곡).
class PlaylistTrackPreview extends Equatable {
  const PlaylistTrackPreview({
    required this.id,
    required this.title,
    required this.artist,
  });

  final String id;
  final String title;

  /// 모르면 빈 문자열.
  final String artist;

  @override
  List<Object?> get props => [id, title, artist];
}

/// 재생목록 하나 (상세 기능: 재생목록 관리 #20).
class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    this.trackCount = 0,
    this.colorIndex,
    this.topTracks = const [],
    this.topArtists = const [],
  });

  final String id;
  final String name;
  final int trackCount;

  /// 이미지가 없을 때 카드 색. 글로우 톤 번호이고, 안 골랐으면 null (이름으로 자동).
  final int? colorIndex;

  /// 이 재생목록에서 많이 들은 곡 (들은 기록이 있을 때만, 많은 순).
  final List<PlaylistTrackPreview> topTracks;

  /// 이 재생목록에 곡이 많은 아티스트 (많은 순, 모르는 아티스트는 뺌).
  final List<String> topArtists;

  @override
  List<Object?> get props => [
    id,
    name,
    trackCount,
    colorIndex,
    topTracks,
    topArtists,
  ];
}
