import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/media_info.dart';
import '../../domain/entities/saved_video.dart';
import '../../domain/entities/video_quality.dart';
import '../../domain/repositories/saved_video_repository.dart';

/// shared_preferences에 보관한 영상 목록을 JSON으로 저장한다 (깨진 항목은 건너뛴다).
class PrefsSavedVideoRepository implements SavedVideoRepository {
  static const _key = 'search.savedVideos';

  @override
  Future<List<SavedVideo>> load() async {
    final raw = (await SharedPreferences.getInstance()).getStringList(_key);
    final out = <SavedVideo>[];
    for (final line in raw ?? const <String>[]) {
      try {
        final m = jsonDecode(line) as Map<String, dynamic>;
        final ms = m['durationMs'] as int?;
        out.add(
          SavedVideo(
            hit: MediaHit(
              id: m['id'] as String,
              title: m['title'] as String? ?? '',
              url: m['url'] as String,
              uploader: m['uploader'] as String? ?? '',
              thumbnailUrl: m['thumbnail'] as String?,
              duration: ms == null ? null : Duration(milliseconds: ms),
            ),
            streamId: m['streamId'] as String?,
            ready: m['ready'] as bool? ?? false,
            quality: VideoQuality.values
                .where((q) => q.name == m['quality'])
                .firstOrNull,
          ),
        );
      } on Object {
        continue;
      }
    }
    return out;
  }

  @override
  Future<void> save(List<SavedVideo> videos) async {
    await (await SharedPreferences.getInstance()).setStringList(_key, [
      for (final v in videos)
        jsonEncode({
          'id': v.hit.id,
          'title': v.hit.title,
          'url': v.hit.url,
          'uploader': v.hit.uploader,
          'thumbnail': v.hit.thumbnailUrl,
          'durationMs': v.hit.duration?.inMilliseconds,
          'streamId': v.streamId,
          'ready': v.ready,
          'quality': v.quality?.name,
        }),
    ]);
  }
}
