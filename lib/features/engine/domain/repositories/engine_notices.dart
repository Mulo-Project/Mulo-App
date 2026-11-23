import '../entities/engine_notice.dart';

/// 받기 엔진 소식 구독.
abstract interface class EngineNotices {
  Stream<EngineNotice> watch();
}
