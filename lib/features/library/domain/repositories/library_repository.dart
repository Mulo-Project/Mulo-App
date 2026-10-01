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

/// 음악을 불러오는 폴더 목록 (상세 기능: 불러오는 폴더 목록).
abstract interface class LoadedFolderRepository {
  /// 기본 저장 위치. 항상 목록에 포함되고 지울 수 없다.
  String get defaultFolder;

  /// 사용자가 추가한 폴더 (기본 저장 위치 제외).
  Future<List<String>> loadExtra();

  Future<void> saveExtra(List<String> folders);

  /// 폴더 고르기. 취소하면 null.
  Future<String?> pickFolder();
}
