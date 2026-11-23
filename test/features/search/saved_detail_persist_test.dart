import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/data/repositories/prefs_saved_video_repository.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/saved_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('저장한 곡의 상세 정보는 다시 읽어도 그대로 남는다', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsSavedVideoRepository();
    await repo.save([
      SavedVideo(
        hit: MediaHit(
          id: 'v',
          title: '곡',
          url: 'https://example.com/v',
          uploader: '채널',
          description: '설명 글',
          viewCount: 1200,
          likeCount: 30,
          uploadedAt: DateTime(2026, 3, 5),
          categories: const ['Music'],
          channelUrl: 'https://example.com/c',
          subscriberCount: 99,
          creators: const ['채널', '게스트'],
          album: '앨범',
        ),
      ),
    ]);
    final hit = (await PrefsSavedVideoRepository().load()).single.hit;
    expect(hit.description, '설명 글');
    expect(hit.viewCount, 1200);
    expect(hit.likeCount, 30);
    expect(hit.uploadedAt, DateTime(2026, 3, 5));
    expect(hit.categories, ['Music']);
    expect(hit.channelUrl, 'https://example.com/c');
    expect(hit.subscriberCount, 99);
    expect(hit.creators, ['채널', '게스트']);
    expect(hit.album, '앨범');
  });
}
