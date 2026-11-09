import '../entities/video_quality.dart';

/// 미리 듣기 영상 화질 설정 저장소.
abstract interface class VideoQualityRepository {
  Future<VideoQuality> load();

  Future<void> save(VideoQuality value);
}
