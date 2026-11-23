import '../entities/media_info.dart';

/// 저장한 곡의 상세 정보(설명 · 조회수 · 좋아요 · 올린 날 · 분류 · 채널)를 글 파일로 함께 남기는 저장소.
abstract interface class SavedDetailStore {
  /// [hit]의 상세 정보를 곡 id 하나당 텍스트 파일 하나로 쓴다 (이미 있으면 덮어쓴다).
  Future<void> write(MediaHit hit);

  /// 곡 id의 상세 정보 파일을 지운다 (없으면 아무 일도 없다).
  Future<void> delete(String id);
}
