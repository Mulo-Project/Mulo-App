import '../entities/engine_status.dart';

/// 이 기기의 yt-dlp를 확인하고 설치한다.
abstract interface class EngineManager {
  Future<EngineStatus> status();

  /// 공식 최신 릴리스를 받아 앱 전용 폴더에 설치(이미 있으면 덮어써 업데이트)한다.
  /// 실패하면 예외를 던진다.
  Future<EngineStatus> install();
}
