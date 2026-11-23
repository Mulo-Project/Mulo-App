import 'package:equatable/equatable.dart';

/// 새 영상 알림의 "바로 받기" 버튼으로 들어온 받기 요청.
class NewVideoDownloadRequest extends Equatable {
  const NewVideoDownloadRequest({
    required this.videoId,
    required this.title,
    required this.channelId,
    this.channelName = '',
    this.thumbnailUrl,
    this.background = false,
  });

  final String videoId;
  final String title;
  final String channelId;
  final String channelName;
  final String? thumbnailUrl;

  /// 앱이 화면에 없는 상태에서 알림 버튼으로 켜졌는지 (받기를 시작한 뒤 앱을 다시 뒤로 보낸다).
  final bool background;

  String get url => 'https://www.youtube.com/watch?v=$videoId';

  @override
  List<Object?> get props => [
    videoId,
    title,
    channelId,
    channelName,
    thumbnailUrl,
    background,
  ];
}
