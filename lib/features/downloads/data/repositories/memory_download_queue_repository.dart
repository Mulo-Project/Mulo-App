import 'dart:async';

import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/repositories/download_queue_repository.dart';

/// 메모리 대기열. 비어 있는 채로 시작하며, 다운로드 엔진(서버 · 로컬)이 연결되면
/// 실제 저장소로 바꾼다. 엔진이 없어서 넣은 항목은 "대기" 상태로 머문다.
class MemoryDownloadQueueRepository implements DownloadQueueRepository {
  final _items = <DownloadItem>[];
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
    _changes.add([..._items]);
  }
}
