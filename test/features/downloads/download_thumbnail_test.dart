import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/data/repositories/memory_download_queue_repository.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';

void main() {
  test('받기 요청의 영상 대표 이미지가 대기열 항목에 이어진다', () async {
    final repo = MemoryDownloadQueueRepository();
    await repo.enqueue(
      const DownloadRequest(title: 'A', thumbnailUrl: 'https://i.test/a.jpg'),
    );
    final items = await repo.watchQueue().first;
    expect(items.single.thumbnailUrl, 'https://i.test/a.jpg');
  });
}
