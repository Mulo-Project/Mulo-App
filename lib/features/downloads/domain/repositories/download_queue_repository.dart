import '../entities/download_item.dart';
import '../entities/download_request.dart';
import '../entities/download_source.dart';

/// 다운로드 대기열 저장소.
abstract interface class DownloadQueueRepository {
  /// 대기열 전체 (받는 순서). 바뀔 때마다 다시 흘려보낸다.
  Stream<List<DownloadItem>> watchQueue();

  /// 같은 원본 주소의 곡을 이미 받았는지 · 받는 중인지 (재생목록 가져오기가 건너뛸 곡을 가린다).
  Future<ExistingDownload> findExisting(String url);

  /// 이미 받아 보관함에 있는 곡들의 원본 주소 키 ([downloadSourceKey]). 곡을 받거나 지울 때마다 다시 흘려보낸다.
  Stream<Set<String>> watchDownloadedKeys();

  /// 앱에서 받은 곡 [trackId]의 원본 주소. 기록이 없으면(기기에서 불러온 곡 등) null.
  Future<String?> sourceUrlOf(String trackId);

  /// 받기를 대기열에 넣는다.
  Future<void> enqueue(DownloadRequest request);

  /// 받는 중이거나 대기 중인 항목을 일시정지한다.
  Future<void> pause(String id);

  /// 일시정지한 항목을 다시 받는다 (대기열 맨 뒤에서 이어서).
  Future<void> resume(String id);

  /// 실패한 항목을 처음부터 다시 받는다 (대기열 맨 뒤에서).
  Future<void> retry(String id);

  /// 항목을 대기열에서 뺀다 (받던 중이면 멈추고 버린다).
  Future<void> cancel(String id);

  /// 끝나지 않은 항목(받는 중 · 대기 · 일시정지 · 실패)을 모두 뺀다. [playlistId]를 주면
  /// 그 재생목록에 담기로 한 항목만 뺀다. 뺀 곡 수를 돌려준다.
  Future<int> cancelAll({String? playlistId});
}
