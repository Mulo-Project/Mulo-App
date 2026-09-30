import '../../../../core/usecase/usecase.dart';
import '../entities/download_item.dart';
import '../entities/download_request.dart';
import '../repositories/download_queue_repository.dart';

/// 대기열 구독 (상세 기능: 다운로드 대기열 #7).
class WatchDownloadQueue
    implements StreamUseCase<List<DownloadItem>, NoParams> {
  const WatchDownloadQueue(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Stream<List<DownloadItem>> call(NoParams params) => _repo.watchQueue();
}

/// 받기 시작: 팝업에서 정한 정보로 대기열에 넣는다 (상세 기능: 곡 정보 편집, 재생목록에 담기).
/// 제목이 비어 있으면 받을 수 없다.
class EnqueueDownload implements UseCase<bool, DownloadRequest> {
  const EnqueueDownload(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<bool> call(DownloadRequest request) async {
    if (request.title.trim().isEmpty) return false;
    await _repo.enqueue(request.normalized());
    return true;
  }
}
