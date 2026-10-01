import 'package:equatable/equatable.dart';

/// 재생목록 카드에 크게 보여 줄 대표곡 하나.
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
    this.featured,
    this.trackIds = const {},
  });

  /// 좋아요 목록의 고정 id. 저장소가 항상 맨 앞에 하나 둔다 (지우거나 이름을 바꿀 수 없다).
  static const favoritesId = 'favorites';

  final String id;

  /// 좋아요 목록은 비어 있다 (화면에서 번역된 이름으로 바꿔 보여 준다).
  final String name;
  final int trackCount;

  /// 이미지가 없을 때 카드 색. 글로우 톤 번호이고, 안 골랐으면 null (이름으로 자동).
  final int? colorIndex;

  /// 카드에 보여 줄 대표곡: 이 재생목록에서 가장 많이 들은 곡, 들은 기록이 없으면 가장 먼저 담은 곡.
  final PlaylistTrackPreview? featured;

  /// 담긴 곡 id (좋아요 표시 · 담기 선택에서 이미 담겼는지 볼 때 쓴다).
  final Set<String> trackIds;

  bool get isFavorites => id == favoritesId;

  @override
  List<Object?> get props => [
    id,
    name,
    trackCount,
    colorIndex,
    featured,
    trackIds,
  ];
}
