import '../entities/hidden_track.dart';
import '../entities/import_result.dart';
import '../entities/track.dart';
import '../entities/track_info.dart';

/// 보관함 저장소.
abstract interface class LibraryRepository {
  /// 추가일 최신순. DB가 바뀌면 새 목록을 흘려보낸다.
  Stream<List<Track>> watchTracks();

  /// 곡을 추가한다. 같은 재생 주소(uri)가 이미 있으면 건너뛴다. 새로 추가된 수를 돌려준다.
  Future<int> addTracks(List<Track> tracks);

  /// 곡의 제목 · 아티스트 · 앨범 · 장르를 바꾼다. 곡이 없으면 false.
  Future<bool> updateInfo(String trackId, TrackInfo info);

  /// 곡을 보관함에서 숨긴다 (불러오는 폴더를 뺄 때). 재생 기록 · 재생목록 · 커버는 남기고,
  /// 같은 곡을 다시 [addTracks]로 찾으면 숨김이 풀린다.
  Future<void> hide(String trackId);

  /// 숨긴 곡(폴더를 빼서 남겨 둔 곡)의 수.
  Future<int> hiddenCount();

  /// 숨긴 곡과 곡마다 남은 기록 (재생 횟수 · 마지막 재생 · 재생목록 수 · 커버 · 가사). 제목순.
  Future<List<HiddenTrack>> hiddenTracks();

  /// 숨긴 곡의 행과 재생 기록 · 재생목록 소속 · 커버 · 커버 색 · 가사 연결을 지운다
  /// (앱 폴더에 복사한 커버 · 가사 파일도). [ids]를 주면 그 중 숨긴 곡만, 없으면 모두.
  /// 보이는 곡은 [ids]에 있어도 건드리지 않는다. 지운 곡 수를 돌려준다.
  Future<int> purgeHidden({Set<String>? ids});

  /// 곡을 보관함에서 지운다. 재생목록 · 재생 기록 · 커버 기록도 함께 지운다 (음악 파일은 [TrackFileRepository]).
  Future<void> delete(String trackId);
}

/// 곡의 음악 파일 (기기에 저장된 파일 자체).
abstract interface class TrackFileRepository {
  /// 음악 파일을 지운다. 이미 없으면 지운 것으로 본다.
  /// 못 지우면(권한 거절 · 사용자가 취소 등) false.
  Future<bool> deleteFile(Track track);
}

/// 기기의 음악 파일 찾기 (상세 기능: 기기 음악 불러오기 #11).
abstract interface class DeviceMusicRepository {
  /// [folders] 안(하위 폴더 포함)의 음악만 찾는다.
  Future<ScanResult> scan(List<String> folders);
}

/// 음악 파일에 내장된 커버 이미지 (ID3 APIC · m4a covr · FLAC picture 등).
abstract interface class EmbeddedCoverRepository {
  /// [track] 파일의 내장 커버를 작게 줄인 임시 이미지 파일 경로. 없거나 못 읽으면 null.
  /// 쓴 뒤에는 [discard]로 지운다.
  Future<String?> extract(Track track);

  Future<void> discard(String path);
}

/// 음악을 불러오는 폴더 목록 (상세 기능: 불러오는 폴더 목록).
abstract interface class LoadedFolderRepository {
  /// 기본 저장 위치. 항상 목록에 포함되고 지울 수 없다.
  String get defaultFolder;

  /// 사용자가 추가한 폴더 (기본 저장 위치 제외).
  Future<List<String>> loadExtra();

  Future<void> saveExtra(List<String> folders);

  /// 불러오는 폴더 목록이 바뀔 때마다 (보관함에 보일 곡을 다시 거르도록).
  Stream<void> watchChanges();

  /// 저장 위치 목록 (기본 저장 위치 제외). 불러오는 폴더와는 따로 저장한다.
  /// 한 번도 저장한 적이 없으면 null (그때는 불러오는 폴더를 처음 목록으로 쓴다).
  Future<List<String>?> loadSaveLocations();

  Future<void> saveSaveLocations(List<String> folders);

  /// 폴더 고르기. 취소하면 null.
  Future<String?> pickFolder();
}
