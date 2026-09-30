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
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String artist;
  final DownloadStatus status;

  /// 0 ~ 1.
  final double progress;
  final String? thumbnailUrl;

  /// 아직 끝나지 않은 항목 (받는 중 · 대기 · 일시정지).
  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.queued ||
      status == DownloadStatus.paused;

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    status,
    progress,
    thumbnailUrl,
  ];
}
