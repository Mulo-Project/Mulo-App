import 'package:equatable/equatable.dart';

/// 소리 없이 화면만 보여 줄 영상 스트림 주소 (미니 플레이어 · 플레이어의 영상 표시용).
/// 주소는 잠시 뒤 만료되므로 오래 들고 있지 않는다.
class VideoStream extends Equatable {
  const VideoStream({required this.url, this.headers = const {}});

  final String url;

  /// 스트림을 받을 때 같이 보내야 하는 요청 헤더 (yt-dlp가 알려 준 것).
  final Map<String, String> headers;

  @override
  List<Object?> get props => [url, headers];
}
