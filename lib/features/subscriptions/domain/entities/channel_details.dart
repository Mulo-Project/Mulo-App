import 'package:equatable/equatable.dart';

/// 채널 정보 시트에 보여 줄 채널 상세 (배너 · 구독자 수).
class ChannelDetails extends Equatable {
  const ChannelDetails({this.bannerUrl, this.logoUrl, this.subscriberCount});

  /// 채널 배너 이미지. 없으면 null.
  final String? bannerUrl;
  final String? logoUrl;
  final int? subscriberCount;

  @override
  List<Object?> get props => [bannerUrl, logoUrl, subscriberCount];
}
