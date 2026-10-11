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
    this.musicOnly = false,
  });

  /// 유튜브 채널 id (`UC…`).
  final String id;
  final String name;
  final String url;
  final String? thumbnailUrl;

  /// 꺼 두면 새 영상을 확인하지 않는다 (구독은 그대로).
  final bool enabled;

  /// 켜면 분류가 음악(Music)인 영상만 새 영상으로 보여 준다.
  final bool musicOnly;

  /// 이 시각 이후에 올라온 영상이 "새 영상". 구독할 때 지금으로 잡아 기존 영상은 보이지 않는다.
  final DateTime baselineAt;

  SubscribedChannel copyWith({
    bool? enabled,
    bool? musicOnly,
    DateTime? baselineAt,
  }) => SubscribedChannel(
    id: id,
    name: name,
    url: url,
    thumbnailUrl: thumbnailUrl,
    enabled: enabled ?? this.enabled,
    musicOnly: musicOnly ?? this.musicOnly,
    baselineAt: baselineAt ?? this.baselineAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    url,
    thumbnailUrl,
    enabled,
    musicOnly,
    baselineAt,
  ];
}
