import '../../../covers/domain/entities/cover_art.dart';
import '../entities/track.dart';

/// 곡 파일의 태그에 정보를 쓴다 (파일이 곡 정보의 원본이 되도록).
abstract interface class TrackTagRepository {
  /// [track]의 제목 · 아티스트 · 앨범 · 장르(와 [cover])를 파일 태그에 쓴다.
  /// 쓸 수 없는 형식 · 권한 없음 · 파일 없음은 false (파일은 그대로 둔다).
  Future<bool> write(Track track, {CoverArt? cover, int? color});
}

/// 이미 태그를 쓴 곡 id 기록 (기존 파일 이관을 이어서 하려고).
abstract interface class TagMigrationStore {
  Future<Set<String>> loadDone();
  Future<void> markDone(Iterable<String> trackIds);
}
