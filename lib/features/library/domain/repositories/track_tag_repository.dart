import '../../../covers/domain/entities/cover_art.dart';
import '../entities/file_tags.dart';
import '../entities/track.dart';

/// 곡 파일의 태그에 정보를 쓴다 (파일이 곡 정보의 원본이 되도록).
abstract interface class TrackTagRepository {
  /// [track]의 제목 · 아티스트 · 앨범 · 장르(와 [cover])를 파일 태그에 쓴다.
  /// 쓸 수 없는 형식 · 권한 없음 · 파일 없음은 false (파일은 그대로 둔다).
  Future<bool> write(Track track, {CoverArt? cover, int? color});
}

/// 곡 파일의 태그를 읽는다 ([TrackTagRepository]의 반대 방향: 파일 → 앱 DB).
abstract interface class FileTagRepository {
  /// [track] 파일의 태그. 지원하지 않는 형식이거나 태그가 없으면 [FileTags.none],
  /// 파일을 못 읽었으면(권한 · 복사 실패 등) null (나중에 다시 시도한다).
  Future<FileTags?> read(Track track);
}

/// 이미 태그를 읽어 DB를 채운 곡 id 기록 (곡마다 한 번만, 이어서 하려고).
abstract interface class TagRestoreStore {
  Future<Set<String>> loadDone();
  Future<void> markDone(Iterable<String> trackIds);
}

/// 이미 태그를 쓴 곡 id 기록 (기존 파일 이관을 이어서 하려고).
abstract interface class TagMigrationStore {
  Future<Set<String>> loadDone();
  Future<void> markDone(Iterable<String> trackIds);
}
