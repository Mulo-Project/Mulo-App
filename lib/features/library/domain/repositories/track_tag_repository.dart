import '../../../covers/domain/entities/cover_art.dart';
import '../entities/file_tags.dart';
import '../entities/track.dart';

/// 태그 쓰기 결과.
enum TagWriteResult {
  /// 파일 태그에 썼다.
  written,

  /// 이 곡은 태그를 쓰지 않는다 (ffmpeg가 없는 빌드 · mp3 · opus가 아닌 형식 · 주소 없음 · 파일 없음).
  /// 앱 DB만 고치는 기존 경로를 따른다.
  unsupported,

  /// 쓰려 했지만 기기 파일에 쓸 권한이 없다.
  denied,

  /// 태그를 쓰려 했지만 실패했다 (변환 · 복사 · 덮어쓰기 오류).
  failed,
}

/// 곡 파일의 태그에 정보를 쓴다 (파일이 곡 정보의 원본이 되도록).
abstract interface class TrackTagRepository {
  /// [track]의 제목 · 아티스트 · 앨범 · 장르(와 [cover])를 파일 태그에 쓴다.
  /// 실패해도 파일은 그대로 둔다.
  Future<TagWriteResult> write(Track track, {CoverArt? cover, int? color});

  /// [track] 파일의 가사 태그에 [lyrics] 글(싱크 가사면 `.lrc` 원문)을 쓴다. 다른 태그는 건드리지 않는다.
  /// 비어 있으면 쓰지 않는다 (이미 파일에 있는 가사는 지워지지 않는다).
  Future<TagWriteResult> writeLyrics(Track track, String lyrics);

  /// 마지막 쓰기가 실패한 이유 (진단용 짧은 글). 없으면 null.
  String? get lastFailure;
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
