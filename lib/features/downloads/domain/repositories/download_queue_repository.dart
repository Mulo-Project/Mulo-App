import '../entities/download_item.dart';
import '../entities/download_request.dart';

/// 다운로드 대기열 저장소.
abstract interface class DownloadQueueRepository {
  /// 대기열 전체 (받는 순서). 바뀔 때마다 다시 흘려보낸다.
  Stream<List<DownloadItem>> watchQueue();

  /// 받기를 대기열에 넣는다.
  Future<void> enqueue(DownloadRequest request);
}
