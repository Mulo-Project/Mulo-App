import '../../../../core/usecase/usecase.dart';
import '../entities/download_item.dart';
import '../repositories/download_queue_repository.dart';

/// 대기열 구독 (상세 기능: 다운로드 대기열 #7).
class WatchDownloadQueue
    implements StreamUseCase<List<DownloadItem>, NoParams> {
  const WatchDownloadQueue(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Stream<List<DownloadItem>> call(NoParams params) => _repo.watchQueue();
}
