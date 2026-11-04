import 'package:equatable/equatable.dart';

import 'track.dart';

/// 폴더를 빼서 숨겨 둔 곡과 그 곡에 남은 기록 (지우면 사라지는 것들).
class HiddenTrack extends Equatable {
  const HiddenTrack({
    required this.track,
    this.playCount = 0,
    this.lastPlayedAt,
    this.playlistCount = 0,
    this.hasCover = false,
    this.hasLyrics = false,
  });

  final Track track;
  final int playCount;
  final DateTime? lastPlayedAt;

  /// 이 곡이 들어 있는 재생목록 수 (좋아요 목록 포함).
  final int playlistCount;
  final bool hasCover;
  final bool hasLyrics;

  @override
  List<Object?> get props => [
    track,
    playCount,
    lastPlayedAt,
    playlistCount,
    hasCover,
    hasLyrics,
  ];
}
