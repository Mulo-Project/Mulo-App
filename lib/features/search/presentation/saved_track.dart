import '../../library/domain/entities/track.dart';
import '../domain/entities/saved_video.dart';

/// 임시 저장한 음원을 메인 재생 대기열에 넣을 곡으로 바꾼다 (끝까지 받은 곡만 쓴다).
/// 받아 둔 데이터는 주소의 캐시로 읽으므로 오프라인에서도 튼다. 파일이 아니라서 재생 기록은 남기지 않는다.
Track? savedTrackOf(SavedVideo v) {
  final url = v.audioSource?.url;
  if (!v.ready || url == null || url.isEmpty) return null;
  return Track(
    id: '${Track.savedIdPrefix}${v.id}',
    title: v.hit.title,
    artist: v.hit.uploader,
    album: '',
    duration: v.hit.duration ?? Duration.zero,
    addedAt: DateTime.fromMillisecondsSinceEpoch(0),
    uri: url,
    source: TrackSource.saved,
  );
}

/// 대기열 곡 id에서 저장한 영상 id를 뽑는다 (저장한 음원이 아니면 null).
String? savedVideoIdOf(String trackId) =>
    trackId.startsWith(Track.savedIdPrefix)
    ? trackId.substring(Track.savedIdPrefix.length)
    : null;
