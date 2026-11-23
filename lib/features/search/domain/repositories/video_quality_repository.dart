import '../entities/video_quality.dart';

/// 미리 듣기 영상 화질 설정 저장소.
abstract interface class VideoQualityRepository {
  Future<VideoQuality> load();

  Future<void> save(VideoQuality value);

  /// 자동(낮은 화질로 먼저 시작해 높인다) 사용 여부.
  Future<bool> loadAuto();

  Future<void> saveAuto(bool value);
}
