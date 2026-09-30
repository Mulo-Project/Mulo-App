import '../../../../core/sample/sample_data.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/repositories/download_queue_repository.dart';

/// 자리 표시 대기열. 다운로드 엔진(서버 · 로컬)이 연결되면 실제 저장소로 바꾼다.
class SampleDownloadQueueRepository implements DownloadQueueRepository {
  const SampleDownloadQueueRepository();

  @override
  Stream<List<DownloadItem>> watchQueue() {
    final t = SampleData.tracks;
    DownloadItem item(int i, DownloadStatus s, double p) => DownloadItem(
      id: t[i].id,
      title: t[i].title,
      artist: t[i].artist,
      status: s,
      progress: p,
    );
    return Stream.value([
      item(3, DownloadStatus.downloading, .72),
      item(5, DownloadStatus.queued, 0),
      item(6, DownloadStatus.queued, 0),
      item(7, DownloadStatus.paused, .45),
      item(9, DownloadStatus.done, 1),
    ]);
  }
}
