import 'package:equatable/equatable.dart';

import 'download_options.dart';

/// 받기 팝업에서 사용자가 정한 것: 곡 정보 · 장르 · 받은 뒤 넣을 재생목록.
class DownloadRequest extends Equatable {
  const DownloadRequest({
    required this.title,
    this.artist = '',
    this.genre = '',
    this.playlistIds = const {},
    this.quality = Quality.best,
    this.savePath = '',
    this.duration,
    this.color,
  });

  final String title;

  /// 모르면 빈 문자열.
  final String artist;
  final String genre;
  final Set<String> playlistIds;
  final Quality quality;

  /// 받은 곡을 저장할 폴더. 비어 있으면 기본 저장 위치.
  final String savePath;

  /// 곡 길이. 모르면 null (대기열 타일에 그대로 이어서 보여 준다).
  final Duration? duration;

  /// 받은 곡의 커버 색(ARGB). 비어 있으면 자동 색.
  final int? color;

  /// 문자열 앞뒤 공백을 지운 사본.
  DownloadRequest normalized() => DownloadRequest(
    title: title.trim(),
    artist: artist.trim(),
    genre: genre.trim(),
    playlistIds: playlistIds,
    quality: quality,
    savePath: savePath.trim(),
    duration: duration,
    color: color,
  );

  @override
  List<Object?> get props => [
    title,
    artist,
    genre,
    playlistIds,
    quality,
    savePath,
    duration,
    color,
  ];
}
