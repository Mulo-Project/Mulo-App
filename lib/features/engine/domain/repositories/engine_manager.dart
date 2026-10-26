import '../entities/engine_status.dart';

/// 이 기기의 yt-dlp를 확인하고 설치한다.
abstract interface class EngineManager {
  Future<EngineStatus> status();

  /// 공식 최신 릴리스를 받아 앱 전용 폴더에 설치(이미 있으면 덮어써 업데이트)한다.
  /// 실패하면 예외를 던진다.
  Future<EngineStatus> install();

  /// 앱이 받아 둔 yt-dlp를 지운다 (받은 것이 없으면 아무것도 하지 않는다). 지운 뒤 상태를 돌려준다.
  /// Android full은 업데이트로 받은 것을 지워 APK에 들어 있던 버전으로 돌아간다.
  Future<EngineStatus> remove();
}
