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
    this.channelUrl,
    this.viewCount,
    this.uploadedAt,
    this.description = '',
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
  /// 곡 하나를 자세히 읽었을 때만 있다. 검색 목록 항목은 비어 있다가 뒤에서 채워진다.
  final List<String> categories;

  /// 이미 받은 곡인지 (서버가 알려 준 경우).
  final bool downloaded;

  /// 올린 채널 주소 (모르면 null).
  final String? channelUrl;
  final int? viewCount;

  /// 올린 날 (날짜만 의미 있다).
  final DateTime? uploadedAt;

  /// 영상 설명. 없으면 빈 문자열.
  final String description;

  /// 분류만 채운 사본.
  MediaHit withCategories(List<String> categories) =>
      _copy(categories: categories);

  /// [full](곡 하나를 자세히 읽은 것)에서 이 항목에 없는 정보를 채운 사본.
  /// 목록에서 알던 제목 · 길이 같은 것은 그대로 두고, 비어 있는 것만 더한다.
  MediaHit filledFrom(MediaHit full) => _copy(
    uploader: uploader.isEmpty ? full.uploader : uploader,
    duration: duration ?? full.duration,
    thumbnailUrl: thumbnailUrl ?? full.thumbnailUrl,
    categories: categories.isEmpty ? full.categories : categories,
    channelUrl: channelUrl ?? full.channelUrl,
    viewCount: viewCount ?? full.viewCount,
    uploadedAt: uploadedAt ?? full.uploadedAt,
    description: description.isEmpty ? full.description : description,
  );

  MediaHit _copy({
    String? uploader,
    Duration? duration,
    String? thumbnailUrl,
    List<String>? categories,
    String? channelUrl,
    int? viewCount,
    DateTime? uploadedAt,
    String? description,
  }) => MediaHit(
    id: id,
    title: title,
    url: url,
    uploader: uploader ?? this.uploader,
    duration: duration ?? this.duration,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    categories: categories ?? this.categories,
    downloaded: downloaded,
    channelUrl: channelUrl ?? this.channelUrl,
    viewCount: viewCount ?? this.viewCount,
    uploadedAt: uploadedAt ?? this.uploadedAt,
    description: description ?? this.description,
  );

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
    channelUrl,
    viewCount,
    uploadedAt,
    description,
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
