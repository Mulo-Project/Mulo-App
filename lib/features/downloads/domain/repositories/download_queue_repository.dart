import '../entities/download_item.dart';
import '../entities/download_request.dart';

/// 다운로드 대기열 저장소.
abstract interface class DownloadQueueRepository {
  /// 대기열 전체 (받는 순서). 바뀔 때마다 다시 흘려보낸다.
  Stream<List<DownloadItem>> watchQueue();

  /// 받기를 대기열에 넣는다.
  Future<void> enqueue(DownloadRequest request);

  /// 받는 중이거나 대기 중인 항목을 일시정지한다.
  Future<void> pause(String id);

  /// 일시정지한 항목을 다시 받는다 (대기열 맨 뒤에서 이어서).
  Future<void> resume(String id);

  /// 항목을 대기열에서 뺀다 (받던 중이면 멈추고 버린다).
  Future<void> cancel(String id);
}
