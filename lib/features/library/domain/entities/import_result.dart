import 'track.dart';

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

/// 기기 음악 불러오기 결과 (화면이 안내 문구를 고른다).
sealed class ImportOutcome {
  const ImportOutcome();
}

class ImportAdded extends ImportOutcome {
  const ImportAdded(this.count);

  /// 새로 추가된 곡 수 (0이면 이미 다 있음).
  final int count;
}

class ImportDenied extends ImportOutcome {
  const ImportDenied();
}

class ImportCancelled extends ImportOutcome {
  const ImportCancelled();
}

class ImportFailed extends ImportOutcome {
  const ImportFailed();
}
