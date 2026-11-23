import '../entities/home_summary.dart';

/// 재생 기록 저장소.
abstract interface class PlayHistoryRepository {
  /// 재생 한 번을 저장하고 그 기록의 id를 돌려준다.
  Future<int> recordPlay(PlayRecord record);

  /// [id] 기록의 들은 시간을 [listened]로 고친다.
  Future<void> updateListened(int id, Duration listened);

  /// 전체 재생 기록 (최근 순). 새로 기록되면 다시 흘려보낸다.
  Stream<List<PlayRecord>> watchPlays();
}
