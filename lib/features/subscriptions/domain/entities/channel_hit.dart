import 'package:equatable/equatable.dart';

/// 채널 검색 결과 하나.
class ChannelHit extends Equatable {
  const ChannelHit({
    required this.id,
    required this.name,
    this.description = '',
    this.thumbnailUrl,
  });

  /// 유튜브 채널 id (`UC…`).
  final String id;
  final String name;

  /// 채널 소개 한 토막. 없으면 빈 문자열.
  final String description;
  final String? thumbnailUrl;

  String get url => 'https://www.youtube.com/channel/$id';

  @override
  List<Object?> get props => [id, name, description, thumbnailUrl];
}
