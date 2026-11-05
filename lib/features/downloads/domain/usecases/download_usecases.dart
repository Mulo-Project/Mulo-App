import '../../../../core/usecase/usecase.dart';
import '../entities/download_item.dart';
import '../entities/download_options.dart';
import '../entities/download_preferences.dart';
import '../entities/download_request.dart';
import '../entities/download_source.dart';
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
/// 제목이나 원본 주소가 비어 있으면 받을 수 없다.
class EnqueueDownload implements UseCase<bool, DownloadRequest> {
  const EnqueueDownload(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<bool> call(DownloadRequest request) async {
    if (request.title.trim().isEmpty || request.url.trim().isEmpty) {
      return false;
    }
    await _repo.enqueue(request.normalized());
    return true;
  }
}

/// 이미 받은 곡인지 찾기: 원본 주소가 같은 곡이 보관함에 있거나 대기열에 있는지.
class FindExistingDownload implements UseCase<ExistingDownload, String> {
  const FindExistingDownload(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<ExistingDownload> call(String url) => _repo.findExisting(url);
}

/// 이미 받은 곡들의 원본 주소 키 (받기 버튼을 "받음"으로 보이고 다시 받지 못하게).
class WatchDownloadedKeys implements StreamUseCase<Set<String>, NoParams> {
  const WatchDownloadedKeys(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Stream<Set<String>> call(NoParams params) => _repo.watchDownloadedKeys();
}

/// 받은 곡의 원본 주소 (곡 상세 정보에 보여 준다). 기록이 없으면 null.
class GetTrackSourceUrl implements UseCase<String?, String> {
  const GetTrackSourceUrl(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<String?> call(String trackId) => _repo.sourceUrlOf(trackId);
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

/// 실패한 항목 다시 받기.
class RetryDownload implements UseCase<void, String> {
  const RetryDownload(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<void> call(String id) => _repo.retry(id);
}

/// 항목 취소.
class CancelDownload implements UseCase<void, String> {
  const CancelDownload(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<void> call(String id) => _repo.cancel(id);
}

/// 끝나지 않은 받기를 모두 취소한다 ([playlistId]가 있으면 그 재생목록 것만). 취소한 곡 수를 돌려준다.
class CancelAllDownloads implements UseCase<int, String?> {
  const CancelAllDownloads(this._repo);

  final DownloadQueueRepository _repo;

  @override
  Future<int> call(String? playlistId) =>
      _repo.cancelAll(playlistId: playlistId);
}

/// 설정에서 고를 수 있는 저장 형식.
class GetSelectableFormats implements UseCase<List<AudioFormat>, NoParams> {
  const GetSelectableFormats(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<List<AudioFormat>> call(NoParams _) async => _repo.selectableFormats();
}

/// 기본 저장 위치 읽기.
class LoadSavePath implements UseCase<String, NoParams> {
  const LoadSavePath(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<String> call(NoParams _) => _repo.loadSavePath();
}

/// 고정한 저장 위치 읽기 (고정하지 않았으면 빈 문자열).
class LoadFixedSavePath implements UseCase<String, NoParams> {
  const LoadFixedSavePath(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<String> call(NoParams _) => _repo.loadFixedSavePath();
}

/// 저장 위치 고정 풀기.
class ClearSavePath implements UseCase<void, NoParams> {
  const ClearSavePath(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<void> call(NoParams _) => _repo.clearSavePath();
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

/// 기본 저장 형식 읽기.
class LoadDownloadPreferences
    implements UseCase<DownloadPreferences, NoParams> {
  const LoadDownloadPreferences(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<DownloadPreferences> call(NoParams _) async =>
      DownloadPreferences(format: await _repo.loadFormat());
}

/// 기본 저장 형식 정하기.
class SaveDownloadFormat implements UseCase<void, AudioFormat> {
  const SaveDownloadFormat(this._repo);

  final DownloadSettingsRepository _repo;

  @override
  Future<void> call(AudioFormat format) => _repo.saveFormat(format);
}
