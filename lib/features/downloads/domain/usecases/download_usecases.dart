import '../../../../core/usecase/usecase.dart';
import '../entities/download_item.dart';
import '../entities/download_request.dart';
import '../repositories/download_queue_repository.dart';
import '../repositories/download_settings_repository.dart';

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

/// 일시정지 (상세 기능: 다운로드 대기열 #7).
class PauseDownload implements UseCase<void, String> {
  const PauseDownload(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<void> call(String id) => _repo.pause(id);
}

/// 일시정지한 항목 이어받기.
class ResumeDownload implements UseCase<void, String> {
  const ResumeDownload(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<void> call(String id) => _repo.resume(id);
}

/// 항목 취소.
class CancelDownload implements UseCase<void, String> {
  const CancelDownload(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<void> call(String id) => _repo.cancel(id);
}

/// 기본 저장 위치 읽기.
class LoadSavePath implements UseCase<String, NoParams> {
  const LoadSavePath(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<String> call(NoParams _) => _repo.loadSavePath();
}

/// 기본 저장 위치 정하기. 앞뒤 공백을 지우고, 비어 있으면 바꾸지 않는다.
class SaveSavePath implements UseCase<void, String> {
  const SaveSavePath(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<void> call(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    await _repo.saveSavePath(trimmed);
  }
}

/// 폴더 선택기를 연다. 고른 폴더 경로, 취소하면 null.
class PickSaveFolder implements UseCase<String?, NoParams> {
  const PickSaveFolder(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<String?> call(NoParams _) => _repo.pickFolder();
}
