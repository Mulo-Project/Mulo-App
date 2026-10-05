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
