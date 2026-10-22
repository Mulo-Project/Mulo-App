import 'package:equatable/equatable.dart';

/// 채널 피드에 올라온 영상 하나.
class FeedVideo extends Equatable {
  const FeedVideo({
    required this.id,
    required this.title,
    required this.publishedAt,
    this.author = '',
    this.thumbnailUrl,
    this.viewCount,
  });

  /// 유튜브 videoId.
  final String id;
  final String title;
  final DateTime publishedAt;
  final String author;
  final String? thumbnailUrl;
  final int? viewCount;

  String get url => 'https://www.youtube.com/watch?v=$id';

  @override
  List<Object?> get props => [
    id,
    title,
    publishedAt,
    author,
    thumbnailUrl,
    viewCount,
  ];
}
