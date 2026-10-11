import 'package:equatable/equatable.dart';

/// 구독한 유튜브 채널 하나.
class SubscribedChannel extends Equatable {
  const SubscribedChannel({
    required this.id,
    required this.name,
    required this.baselineAt,
    this.url = '',
    this.thumbnailUrl,
    this.enabled = true,
    this.categories = const {},
  });

  /// 유튜브 채널 id (`UC…`).
  final String id;
  final String name;
  final String url;
  final String? thumbnailUrl;

  /// 꺼 두면 새 영상을 확인하지 않는다 (구독은 그대로).
  final bool enabled;

  /// 알림 · 새 영상 목록에 넣을 유튜브 영상 분류 (yt-dlp의 `categories`, 예: `Music`).
  /// 비어 있으면 모든 분류. 분류를 알 수 없는 영상은 걸러내지 않고 보여 준다.
  final Set<String> categories;

  /// 이 시각 이후에 올라온 영상이 "새 영상". 구독할 때 지금으로 잡아 기존 영상은 보이지 않는다.
  final DateTime baselineAt;

  /// 이 채널이 분류를 걸러서 보여 주는지.
  bool get filtersCategories => categories.isNotEmpty;

  /// 영상의 분류 [videoCategories]가 이 채널의 분류 조건에 맞는지.
  /// 조건이 없거나 영상 분류를 모르면 맞는 것으로 본다.
  bool accepts(List<String> videoCategories) =>
      categories.isEmpty ||
      videoCategories.isEmpty ||
      videoCategories.any(categories.contains);

  SubscribedChannel copyWith({
    bool? enabled,
    Set<String>? categories,
    DateTime? baselineAt,
  }) => SubscribedChannel(
    id: id,
    name: name,
    url: url,
    thumbnailUrl: thumbnailUrl,
    enabled: enabled ?? this.enabled,
    categories: categories ?? this.categories,
    baselineAt: baselineAt ?? this.baselineAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    url,
    thumbnailUrl,
    enabled,
    categories,
    baselineAt,
  ];
}
