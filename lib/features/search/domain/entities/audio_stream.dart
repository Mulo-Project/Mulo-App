import 'package:equatable/equatable.dart';

/// 곡을 받지 않고 바로 들을 수 있는 오디오 스트림 주소 (미리 듣기용).
/// 주소는 잠시 뒤 만료되므로 오래 들고 있지 않는다.
class AudioStream extends Equatable {
  const AudioStream({
    required this.url,
    this.headers = const {},
    this.fallbacks = const [],
    this.hls = false,
    this.codec,
  });

  final String url;

  /// 스트림을 받을 때 같이 보내야 하는 요청 헤더 (yt-dlp가 알려 준 것).
  final Map<String, String> headers;

  /// 이 주소가 안 열릴 때 차례로 써 볼 다른 형식의 주소 (미리 듣기는 형식을 가리지 않고 틀기 위함).
  final List<AudioStream> fallbacks;

  /// 주소가 HLS(m3u8) 목록이다: 파일 하나가 아니라 조각을 모아 합쳐야 받을 수 있다 (사운드클라우드 등).
  final bool hls;

  /// 소리 코덱 이름(yt-dlp가 알려 준 값, 모르면 null). HLS를 합칠 때 네이티브가 담을 형식을 고르는 데 쓴다.
  final String? codec;

  @override
  List<Object?> get props => [url, headers, fallbacks, hls, codec];
}
