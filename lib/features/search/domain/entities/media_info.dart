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
    this.likeCount,
    this.subscriberCount,
    this.channelThumbnailUrl,
    this.creators = const [],
    this.subtitleLangs = const [],
    this.autoSubtitleLangs = const [],
    this.album = '',
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

  /// 좋아요 수 (유튜브는 싫어요 수를 알려 주지 않는다).
  final int? likeCount;

  /// 채널 구독자 수 · 채널 이미지.
  final int? subscriberCount;
  final String? channelThumbnailUrl;

  /// 영상을 함께 올린 채널들의 이름 (유튜브 "공동 작업자"). 대표 채널이 맨 앞이고,
  /// 공동 작업이 아니면 비어 있다. 곡 하나를 자세히 읽었을 때만 있다.
  final List<String> creators;

  /// 영상에 달린 자막의 언어 코드 (사람이 단 것 + 자동 생성). 곡 하나를 자세히 읽었을 때만 있고,
  /// 비어 있으면 자막이 없거나 아직 모른다.
  final List<String> subtitleLangs;

  /// [subtitleLangs] 가운데 자동 생성 자막인 것.
  final List<String> autoSubtitleLangs;

  /// 앨범 이름 (yt-dlp의 `album`, 유튜브 뮤직 곡 등). 모르면 빈 문자열. 곡 하나를 자세히 읽었을 때만 있다.
  final String album;

  /// 분류만 채운 사본.
  MediaHit withCategories(List<String> categories) =>
      _copy(categories: categories);

  /// [full](곡 하나를 자세히 읽은 것)에서 이 항목에 없는 정보를 채운 사본.
  /// 목록에서 알던 제목 · 길이 같은 것은 그대로 두고, 비어 있는 것만 더한다.
  ///
  /// 공동 작업 영상은 목록의 올린 사람이 "A and B"처럼 합쳐진 이름이고 채널 주소도 없다.
  /// 이름만 그대로 두면 채널 주소 · 이미지 · 구독자 수(대표 채널의 것)와 어긋나므로,
  /// 이때는 자세히 읽은 쪽의 대표 채널 이름을 쓴다.
  MediaHit filledFrom(MediaHit full) => _copy(
    uploader: uploader.isEmpty || full.creators.length > 1
        ? full.uploader
        : uploader,
    creators: full.creators,
    subtitleLangs: subtitleLangs.isEmpty ? full.subtitleLangs : subtitleLangs,
    autoSubtitleLangs: subtitleLangs.isEmpty
        ? full.autoSubtitleLangs
        : autoSubtitleLangs,
    album: album.isEmpty ? full.album : album,
    duration: duration ?? full.duration,
    thumbnailUrl: thumbnailUrl ?? full.thumbnailUrl,
    categories: categories.isEmpty ? full.categories : categories,
    channelUrl: channelUrl ?? full.channelUrl,
    viewCount: viewCount ?? full.viewCount,
    uploadedAt: uploadedAt ?? full.uploadedAt,
    // 검색 목록의 설명은 앞부분만 오는 일이 많아서, 자세히 읽은 전체 설명이 있으면 그것을 쓴다.
    description: full.description.isEmpty ? description : full.description,
    likeCount: likeCount ?? full.likeCount,
    subscriberCount: subscriberCount ?? full.subscriberCount,
    channelThumbnailUrl: channelThumbnailUrl ?? full.channelThumbnailUrl,
  );

  /// 채널 정보를 채운 사본.
  MediaHit withChannel(ChannelInfo channel) => _copy(
    subscriberCount: channel.subscriberCount,
    channelThumbnailUrl: channel.thumbnailUrl,
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
    int? likeCount,
    int? subscriberCount,
    String? channelThumbnailUrl,
    List<String>? creators,
    List<String>? subtitleLangs,
    List<String>? autoSubtitleLangs,
    String? album,
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
    likeCount: likeCount ?? this.likeCount,
    subscriberCount: subscriberCount ?? this.subscriberCount,
    channelThumbnailUrl: channelThumbnailUrl ?? this.channelThumbnailUrl,
    creators: creators ?? this.creators,
    subtitleLangs: subtitleLangs ?? this.subtitleLangs,
    autoSubtitleLangs: autoSubtitleLangs ?? this.autoSubtitleLangs,
    album: album ?? this.album,
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
    likeCount,
    subscriberCount,
    channelThumbnailUrl,
    creators,
    subtitleLangs,
    autoSubtitleLangs,
    album,
  ];
}

/// 채널 정보 (상세 보기에서 채널 이미지 · 구독자 수를 보여 주려고).
class ChannelInfo extends Equatable {
  const ChannelInfo({this.thumbnailUrl, this.subscriberCount});

  final String? thumbnailUrl;
  final int? subscriberCount;

  @override
  List<Object?> get props => [thumbnailUrl, subscriberCount];
}

/// 키워드 검색 한 쪽.
class SearchPage extends Equatable {
  const SearchPage({required this.items, required this.hasNext});

  final List<MediaHit> items;
  final bool hasNext;

  @override
  List<Object?> get props => [items, hasNext];
}

/// 재생목록 검색 결과 하나 (곡 목록은 고른 뒤 주소로 읽는다).
class PlaylistHit extends Equatable {
  const PlaylistHit({
    required this.id,
    required this.title,
    required this.url,
    this.channel = '',
    this.thumbnailUrl,
    this.trackCount,
  });

  /// 유튜브 재생목록 id.
  final String id;
  final String title;

  /// 곡 목록을 읽을 재생목록 주소.
  final String url;

  /// 만든 채널 이름. 모르면 빈 문자열.
  final String channel;
  final String? thumbnailUrl;

  /// 곡 수. 모르면 null.
  final int? trackCount;

  @override
  List<Object?> get props => [
    id,
    title,
    url,
    channel,
    thumbnailUrl,
    trackCount,
  ];
}

/// 재생목록 검색 한 쪽.
class PlaylistSearchPage extends Equatable {
  const PlaylistSearchPage({required this.items, required this.hasNext});

  final List<PlaylistHit> items;
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
  const PlaylistInfo({
    required this.title,
    required this.entries,
    this.thumbnailUrl,
  });

  final String title;
  final List<MediaHit> entries;

  /// 재생목록 대표 이미지 주소. 모르면 null.
  final String? thumbnailUrl;

  @override
  List<Object?> get props => [title, entries, thumbnailUrl];
}
