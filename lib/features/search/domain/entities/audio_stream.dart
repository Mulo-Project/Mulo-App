import 'package:equatable/equatable.dart';

/// 곡을 받지 않고 바로 들을 수 있는 오디오 스트림 주소 (미리 듣기용).
/// 주소는 잠시 뒤 만료되므로 오래 들고 있지 않는다.
class AudioStream extends Equatable {
  const AudioStream({required this.url, this.headers = const {}});

  final String url;

  /// 스트림을 받을 때 같이 보내야 하는 요청 헤더 (yt-dlp가 알려 준 것).
  final Map<String, String> headers;

  @override
  List<Object?> get props => [url, headers];
}
