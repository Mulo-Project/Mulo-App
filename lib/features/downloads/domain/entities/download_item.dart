import 'package:equatable/equatable.dart';

import '../../../covers/domain/entities/cover_art.dart';

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
    this.cover,
    this.duration,
    this.color,
    this.url = '',
    this.error = '',
    this.processing = false,
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

  /// 받은 뒤 곡에 붙일 커버. 없으면 자동 커버.
  final CoverArt? cover;

  /// 곡 길이. 모르면 null.
  final Duration? duration;

  /// 받은 뒤 곡에 쓸 커버 색(ARGB). 비어 있으면 자동 색.
  final int? color;

  /// 받을 곡의 원본 주소 (유튜브 등). 다시 받을 때 쓴다.
  final String url;

  /// 실패한 까닭 (사용자에게 보여 줄 안내). 실패가 아니면 빈 문자열.
  final String error;

  /// 내려받기는 끝나고 변환 · 태그 쓰기 · 저장을 하는 중 (진행률은 100%인 채로 한참 걸릴 수 있다).
  final bool processing;

  /// 아직 끝나지 않은 항목 (받는 중 · 대기 · 일시정지).
  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.queued ||
      status == DownloadStatus.paused;

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    String? error,
    bool processing = false,
  }) => DownloadItem(
    id: id,
    title: title,
    artist: artist,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    genre: genre,
    playlistIds: playlistIds,
    thumbnailUrl: thumbnailUrl,
    cover: cover,
    duration: duration,
    color: color,
    url: url,
    error: error ?? this.error,
    processing: processing,
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
    cover,
    duration,
    color,
    url,
    error,
    processing,
  ];
}
