import 'package:equatable/equatable.dart';

/// 검색 결과 · 재생목록 항목 하나 (곡 하나를 가리키는 정보).
class MediaHit extends Equatable {
  const MediaHit({
    required this.id,
    required this.title,
    required this.url,
    this.uploader = '',
    this.duration,
    this.thumbnailUrl,
    this.categories = const [],
    this.downloaded = false,
  });

  /// 사이트 안의 곡 id (유튜브면 videoId).
  final String id;
  final String title;

  /// 받을 때 엔진에 넘기는 주소.
  final String url;

  /// 올린 사람 · 채널. 모르면 빈 문자열.
  final String uploader;
  final Duration? duration;
  final String? thumbnailUrl;

  /// 유튜브가 영상에 붙인 분류 (yt-dlp의 `categories`, 예: `Music`).
  /// 곡 하나를 자세히 읽었을 때만 있고, 검색 목록에는 보통 비어 있다.
  final List<String> categories;

  /// 이미 받은 곡인지 (서버가 알려 준 경우).
  final bool downloaded;

  @override
  List<Object?> get props => [
    id,
    title,
    url,
    uploader,
    duration,
    thumbnailUrl,
    categories,
    downloaded,
  ];
}

/// 키워드 검색 한 쪽.
class SearchPage extends Equatable {
  const SearchPage({required this.items, required this.hasNext});

  final List<MediaHit> items;
  final bool hasNext;

  @override
  List<Object?> get props => [items, hasNext];
}

/// URL로 알아낸 정보: 곡 하나 또는 재생목록.
sealed class MediaInfo extends Equatable {
  const MediaInfo();
}

final class VideoInfo extends MediaInfo {
  const VideoInfo(this.hit);

  final MediaHit hit;

  @override
  List<Object?> get props => [hit];
}

final class PlaylistInfo extends MediaInfo {
  const PlaylistInfo({required this.title, required this.entries});

  final String title;
  final List<MediaHit> entries;

  @override
  List<Object?> get props => [title, entries];
}
