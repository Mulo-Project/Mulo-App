import 'dart:async';

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
  /// 실패해도 파일은 그대로 둔다. [interactive]면 사용자가 직접 한 저장이라, 쓸 권한이 없을 때 시스템 동의 창을 띄운다.
  Future<TagWriteResult> write(
    Track track, {
    CoverArt? cover,
    int? color,
    bool interactive = false,
  });

  /// [track] 파일의 가사 태그에 [lyrics] 글(싱크 가사면 `.lrc` 원문)을 쓴다. 다른 태그는 건드리지 않는다.
  /// 비어 있으면 쓰지 않는다 (이미 파일에 있는 가사는 지워지지 않는다).
  Future<TagWriteResult> writeLyrics(Track track, String lyrics);

  /// [track] 파일에 쓸 수 있는지 확인하고, 못 쓰면 시스템 동의를 구한다 (가사 편집 화면에 들어갈 때).
  /// 쓰지 않는 곡이거나 쓸 수 있으면 true, 거절하면 false.
  Future<bool> ensureWriteAccess(Track track);

  /// [tracks] 파일에 쓸 동의를 시스템 창 한 번으로 구한다 (다중 선택 수정). 이미 쓸 수 있으면 창 없이 true.
  Future<bool> ensureWriteAccessAll(List<Track> tracks);

  /// 마지막 쓰기가 실패한 이유 (진단용 짧은 글). 없으면 null.
  String? get lastFailure;
}

/// 곡 파일의 태그를 읽는다 ([TrackTagRepository]의 반대 방향: 파일 → 앱 DB).
abstract interface class FileTagRepository {
  /// [track] 파일의 태그. 지원하지 않는 형식이거나 태그가 없으면 [FileTags.none],
  /// 파일을 못 읽었으면(권한 · 복사 실패 등) null (나중에 다시 시도한다).
  Future<FileTags?> read(Track track);

  /// 임시 진단: 지금까지 읽은 결과를 종류별로 센 한 줄 (꺼내면 비운다). 없으면 빈 문자열.
  String takeSummary();
}

/// 새로 찾은 곡 중 파일 태그를 아직 읽지 못한 곡 id (처음 불러오는 동안만 있다). 곡 정보(제목 · 커버 등)가 다 채워지기 전에는
/// 곡 줄을 흐리게 하고 누르지 못하게 하는 데 쓴다. 앱 전체에서 하나를 같이 쓴다.
class PendingTagTracks {
  final _controller = StreamController<Set<String>>.broadcast();
  var _ids = <String>{};

  Set<String> get ids => _ids;

  Stream<Set<String>> get changes => _controller.stream;

  void set(Set<String> ids) {
    _ids = ids;
    _controller.add(_ids);
  }

  void remove(String id) {
    if (!_ids.contains(id)) return;
    _ids = {..._ids}..remove(id);
    _controller.add(_ids);
  }

  void clear() {
    if (_ids.isEmpty) return;
    _ids = <String>{};
    _controller.add(_ids);
  }
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
