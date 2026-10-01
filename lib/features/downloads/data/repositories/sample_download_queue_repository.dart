import 'dart:async';

import '../../../../core/sample/sample_data.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/repositories/download_queue_repository.dart';

/// 자리 표시 대기열. 다운로드 엔진(서버 · 로컬)이 연결되면 실제 저장소로 바꾼다.
/// 새로 받기를 시작하면 대기열 끝에 "대기" 항목으로 들어간다 (실제로 받지는 않는다).
class SampleDownloadQueueRepository implements DownloadQueueRepository {
  SampleDownloadQueueRepository() {
    final t = SampleData.tracks;
    DownloadItem item(int i, DownloadStatus s, double p) => DownloadItem(
      id: t[i].id,
      title: t[i].title,
      artist: t[i].artist,
      status: s,
      progress: p,
    );
    _items = [
      item(3, DownloadStatus.downloading, .72),
      item(5, DownloadStatus.queued, 0),
      item(6, DownloadStatus.queued, 0),
      item(7, DownloadStatus.paused, .45),
      item(9, DownloadStatus.done, 1),
    ];
  }

  late final List<DownloadItem> _items;
  final _changes = StreamController<List<DownloadItem>>.broadcast();

  @override
  Stream<List<DownloadItem>> watchQueue() async* {
    yield [..._items];
    yield* _changes.stream;
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    _items.add(
      DownloadItem(
        id: 'd${DateTime.now().microsecondsSinceEpoch}',
        title: request.title,
        artist: request.artist,
        genre: request.genre,
        playlistIds: request.playlistIds,
        status: DownloadStatus.queued,
      ),
    );
    _changes.add([..._items]);
  }

  void _replace(String id, DownloadItem Function(DownloadItem) change) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = change(_items[i]);
    _promote();
  }

  /// 받는 곡이 없으면 대기 중인 첫 곡이 이어서 받는다.
  void _promote() {
    final busy = _items.any((e) => e.status == DownloadStatus.downloading);
    if (!busy) {
      final i = _items.indexWhere((e) => e.status == DownloadStatus.queued);
      if (i >= 0) {
        _items[i] = _items[i].copyWith(status: DownloadStatus.downloading);
      }
    }
    _changes.add([..._items]);
  }

  @override
  Future<void> pause(String id) async => _replace(
    id,
    (e) => e.isActive ? e.copyWith(status: DownloadStatus.paused) : e,
  );

  @override
  Future<void> resume(String id) async => _replace(
    id,
    (e) => e.status == DownloadStatus.paused
        ? e.copyWith(status: DownloadStatus.queued)
        : e,
  );

  @override
  Future<void> cancel(String id) async {
    _items.removeWhere((e) => e.id == id);
    _promote();
  }
}
