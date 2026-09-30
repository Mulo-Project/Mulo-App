import 'track.dart';

/// 보관함 저장소.
abstract interface class LibraryRepository {
  /// 추가일 최신순. DB가 바뀌면 새 목록을 흘려보낸다.
  Stream<List<Track>> watchTracks();

  /// 곡을 추가한다. 같은 재생 주소(uri)가 이미 있으면 건너뛴다. 새로 추가된 수를 돌려준다.
  Future<int> addTracks(List<Track> tracks);
}

/// 기기에서 음악을 찾은 결과.
sealed class ScanResult {
  const ScanResult();
}

class ScanFound extends ScanResult {
  const ScanFound(this.tracks);

  final List<Track> tracks;
}

/// 권한을 거절함 (Android 오디오 권한).
class ScanPermissionDenied extends ScanResult {
  const ScanPermissionDenied();
}

/// 사용자가 취소함 (데스크톱 폴더 고르기).
class ScanCancelled extends ScanResult {
  const ScanCancelled();
}

/// 기기의 음악 파일 찾기 (상세 기능: 기기 음악 불러오기 #11).
abstract interface class DeviceMusicScanner {
  Future<ScanResult> scan();
}
