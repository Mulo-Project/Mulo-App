import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/media_info.dart';
import '../../domain/entities/saved_video.dart';
import '../../domain/entities/video_quality.dart';
import '../../domain/entities/video_stream.dart';
import '../../domain/repositories/saved_video_repository.dart';

/// shared_preferences에 보관한 영상 목록을 JSON으로 저장한다 (깨진 항목은 건너뛴다).
class PrefsSavedVideoRepository implements SavedVideoRepository {
  static const _key = 'search.savedVideos';

  static List<String> _strings(Object? raw) => [
    for (final e in (raw as List<dynamic>? ?? const [])) e.toString(),
  ];

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
              // 저장할 때 읽어 둔 상세 정보: 앱을 다시 켜거나 오프라인이어도 상세 화면에 그대로 보인다.
              description: m['description'] as String? ?? '',
              viewCount: m['viewCount'] as int?,
              likeCount: m['likeCount'] as int?,
              uploadedAt: DateTime.tryParse(m['uploadedAt'] as String? ?? ''),
              categories: _strings(m['categories']),
              channelUrl: m['channelUrl'] as String?,
              subscriberCount: m['subscriberCount'] as int?,
              channelThumbnailUrl: m['channelThumbnail'] as String?,
              creators: _strings(m['creators']),
              album: m['album'] as String? ?? '',
            ),
            streamId: m['streamId'] as String?,
            ready: m['ready'] as bool? ?? false,
            quality: VideoQuality.values
                .where((q) => q.name == m['quality'])
                .firstOrNull,
            sources: [
              for (final s in (m['sources'] as List<dynamic>? ?? const []))
                VideoStream(
                  url: (s as Map<String, dynamic>)['url'] as String,
                  headers: Map<String, String>.from(
                    s['headers'] as Map? ?? const {},
                  ),
                  muxed: s['muxed'] as bool? ?? false,
                ),
            ],
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
          'description': v.hit.description,
          'viewCount': v.hit.viewCount,
          'likeCount': v.hit.likeCount,
          'uploadedAt': v.hit.uploadedAt?.toIso8601String(),
          'categories': v.hit.categories,
          'channelUrl': v.hit.channelUrl,
          'subscriberCount': v.hit.subscriberCount,
          'channelThumbnail': v.hit.channelThumbnailUrl,
          'creators': v.hit.creators,
          'album': v.hit.album,
          'streamId': v.streamId,
          'ready': v.ready,
          'quality': v.quality?.name,
          'sources': [
            for (final s in v.sources)
              {'url': s.url, 'headers': s.headers, 'muxed': s.muxed},
          ],
        }),
    ]);
  }
}
