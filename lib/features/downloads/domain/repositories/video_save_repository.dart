import '../entities/download_options.dart';

/// 영상 파일로 저장하기 요청 (원본 주소와 파일에 붙일 이름).
class VideoSaveRequest {
  const VideoSaveRequest({
    required this.url,
    required this.title,
    this.artist = '',
    this.maxHeight = 1080,
    this.format = VideoFormat.mp4,
  });

  final String url;
  final String title;
  final String artist;

  /// 화질 상한(세로 픽셀). 이 이하에서 가장 좋은 화질을 받는다.
  final int maxHeight;
  final VideoFormat format;
}

/// 영상을 받지 못했다. [message]는 원인 (로그 · 디버깅용).
class VideoSaveException implements Exception {
  const VideoSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 유튜브 등의 영상을 소리까지 합친 mp4 파일로 기기에 저장한다.
abstract interface class VideoSaveRepository {
  /// 이 빌드 · 기기에서 영상 파일을 저장할 수 있는지 (Android full 빌드만).
  Future<bool> isAvailable();

  /// 영상과 소리를 받아 mp4 한 파일로 합쳐 `Movies/Mulo`에 저장한다. 못 하면 [VideoSaveException].
  Future<void> save(VideoSaveRequest request);
}
