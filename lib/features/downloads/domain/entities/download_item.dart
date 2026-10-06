import 'package:equatable/equatable.dart';

enum DownloadStatus { downloading, queued, paused, failed, done }

/// 다운로드 대기열의 곡 하나 (상세 기능: 다운로드 대기열 #7).
class DownloadItem extends Equatable {
  const DownloadItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.status,
    this.progress = 0,
    this.genre = '',
    this.playlistIds = const {},
    this.thumbnailUrl,
    this.duration,
    this.color,
  });

  final String id;
  final String title;
  final String artist;

  /// 받은 뒤 곡에 붙일 장르. 모르면 빈 문자열.
  final String genre;

  /// 받기가 끝나면 곡을 넣을 재생목록 id.
  final Set<String> playlistIds;
  final DownloadStatus status;

  /// 0 ~ 1.
  final double progress;
  final String? thumbnailUrl;

  /// 곡 길이. 모르면 null.
  final Duration? duration;

  /// 받은 뒤 곡에 쓸 커버 색(ARGB). 비어 있으면 자동 색.
  final int? color;

  /// 아직 끝나지 않은 항목 (받는 중 · 대기 · 일시정지).
  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.queued ||
      status == DownloadStatus.paused;

  DownloadItem copyWith({DownloadStatus? status, double? progress}) =>
      DownloadItem(
        id: id,
        title: title,
        artist: artist,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        genre: genre,
        playlistIds: playlistIds,
        thumbnailUrl: thumbnailUrl,
        duration: duration,
        color: color,
      );

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    genre,
    playlistIds,
    status,
    progress,
    thumbnailUrl,
    duration,
    color,
  ];
}
