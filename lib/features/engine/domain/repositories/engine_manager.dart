import '../entities/engine_status.dart';

/// 이 기기의 yt-dlp를 확인하고 설치한다.
abstract interface class EngineManager {
  Future<EngineStatus> status();

  /// 공식 최신 릴리스를 받아 앱 전용 폴더에 설치(이미 있으면 덮어써 업데이트)한다.
  /// 실패하면 예외를 던진다.
  Future<EngineStatus> install();

  /// 앱이 받아 둔 yt-dlp를 지운다 (받은 것이 없으면 아무것도 하지 않는다). 지운 뒤 상태를 돌려준다.
  Future<EngineStatus> remove();

  /// 업데이트로 받은 yt-dlp를 지우고 앱에 들어 있는 버전으로 되돌린다 (Android full).
  /// 되돌릴 수 없는 기기면 [UnsupportedError], 실패하면 그 밖의 예외를 던진다.
  Future<EngineStatus> revertToBundled();
}
