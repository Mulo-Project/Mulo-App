import '../../../core/di/injector.dart';
import '../../library/domain/entities/track.dart';
import '../domain/entities/saved_video.dart';
import '../domain/usecases/search_usecases.dart';

Track _trackOf(SavedVideo v, String url) => Track(
  id: '${Track.savedIdPrefix}${v.id}',
  title: v.hit.title,
  artist: v.hit.uploader,
  album: '',
  duration: v.hit.duration ?? Duration.zero,
  addedAt: DateTime.fromMillisecondsSinceEpoch(0),
  uri: url,
  source: TrackSource.saved,
  hasVideo: v.quality != null && v.videoSource != null,
  videoUri: v.sources.length >= 2 ? v.sources.first.url : '',
);

/// 임시 저장한 음원을 메인 재생 대기열에 넣을 곡으로 바꾼다 (끝까지 받은 곡만 쓴다).
/// 받아 둔 데이터는 주소의 캐시로 읽으므로 오프라인에서도 튼다. 파일이 아니라서 재생 기록은 남기지 않는다.
/// 저장할 때 받은 주소가 없는 옛 저장분은 null (주소를 읽어야 하면 [savedTrackResolved]).
Track? savedTrackOf(SavedVideo v) {
  final url = v.audioSource?.url;
  if (!v.ready || url == null || url.isEmpty) return null;
  return _trackOf(v, url);
}

/// [savedTrackOf]와 같되, 저장 주소가 없는 옛 저장분은 링크를 읽어 주소를 얻는다 (캐시는 영상 id로 읽으므로
/// 받아 둔 데이터를 그대로 쓴다). 못 읽으면 null.
Future<Track?> savedTrackResolved(SavedVideo v) async {
  final direct = savedTrackOf(v);
  if (direct != null || !v.ready) return direct;
  try {
    final stream = await sl<ResolveAudioStream>()(v.hit.url);
    return stream.url.isEmpty ? null : _trackOf(v, stream.url);
  } on Object {
    return null;
  }
}

/// 끝까지 받은 곡을 모두 대기열 곡으로 (순서 유지, 못 만든 곡은 건너뛴다).
Future<List<Track>> savedTracksResolved(Iterable<SavedVideo> videos) async {
  final tracks = await Future.wait(videos.map(savedTrackResolved));
  return [for (final t in tracks) ?t];
}

/// 대기열 곡 id에서 저장한 영상 id를 뽑는다 (저장한 음원이 아니면 null).
String? savedVideoIdOf(String trackId) =>
    trackId.startsWith(Track.savedIdPrefix)
    ? trackId.substring(Track.savedIdPrefix.length)
    : null;
