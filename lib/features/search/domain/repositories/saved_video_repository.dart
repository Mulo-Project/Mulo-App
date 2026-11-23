import '../entities/saved_video.dart';

/// 보관한 영상 목록 저장소 (목록만 든다. 데이터는 [PreviewPlayer]의 보관 저장소에 있다).
abstract interface class SavedVideoRepository {
  /// 보관한 순서대로 (오래된 것이 앞).
  Future<List<SavedVideo>> load();

  Future<void> save(List<SavedVideo> videos);
}
