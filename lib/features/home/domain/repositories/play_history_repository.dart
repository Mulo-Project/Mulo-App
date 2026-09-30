import '../entities/home_summary.dart';

/// 재생 기록 저장소.
abstract interface class PlayHistoryRepository {
  Future<void> recordPlay(PlayRecord record);

  /// 전체 재생 기록 (최근 순). 새로 기록되면 다시 흘려보낸다.
  Stream<List<PlayRecord>> watchPlays();
}
