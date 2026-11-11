import 'track_info.dart';

/// 곡이 어디서 왔는지.
enum TrackSource { device, download, saved }

/// 보관함의 곡 한 개 (같은 id면 같은 곡).
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.addedAt,
    this.genre = '',
    this.uri = '',
    this.folder = '',
    this.source = TrackSource.device,
    this.hasVideo = false,
    this.videoUri = '',
  });

  final String id;
  final String title;

  /// 모르면 빈 문자열 (화면에서 "알 수 없는 아티스트"로 보여 준다).
  final String artist;
  final String album;

  /// 모르면 빈 문자열.
  final String genre;
  final Duration duration;
  final DateTime addedAt;

  /// 재생 주소 (Android content://, 데스크톱 파일 경로).
  final String uri;

  /// 파일이 들어 있는 폴더 경로 (불러오는 폴더별 곡 수에 쓴다). 모르면 빈 문자열.
  final String folder;
  final TrackSource source;

  /// 영상도 같이 나오는 임시 저장 곡 (영상으로 저장했다). 영상은 네이티브가 소리와 한 시계로 낸다.
  final bool hasVideo;

  /// 영상 전용 주소 (소리와 따로 저장한 경우). 소리 주소가 영상까지 담고 있으면 빈 문자열.
  final String videoUri;

  /// 영상 파일인가 (보관함에서 영상도 곡으로 불러온다). 소리는 네이티브가, 화면은 Dart가 같은 파일로 낸다.
  bool get isVideo =>
      hasVideo ||
      id.startsWith(videoIdPrefix) ||
      id.startsWith(downloadedVideoIdPrefix) ||
      // 영상으로 받아 MediaStore 영상 모음에 저장한 곡 (예전에 받은 곡은 id로 알 수 없어 주소로 안다).
      uri.startsWith('content://media/external/video/') ||
      (id.startsWith('file:') &&
          _videoExtensions.any(uri.toLowerCase().endsWith));

  /// 임시 저장한 음원(캐시)인가. 파일이 아니라 받아 둔 스트림이라 재생 기록 · 재생 횟수를 남기지 않는다.
  bool get isSaved => source == TrackSource.saved;

  /// 임시 저장한 음원 곡의 id 앞머리 (뒤는 영상 id).
  static const savedIdPrefix = 'saved:';

  /// 기기에서 불러온 영상 곡의 id 앞머리.
  static const videoIdPrefix = 'device-video:';

  /// 영상으로 받아 저장한 곡의 id 앞머리 (뒤는 받기 id). 이 곡은 영상 파일이라 영상으로 재생한다.
  static const downloadedVideoIdPrefix = 'download:video:';

  static const _videoExtensions = ['.mp4', '.mkv', '.webm', '.mov', '.m4v'];

  /// 편집한 정보를 반영한 새 곡 (id · 재생 주소 등은 그대로).
  Track withInfo(TrackInfo info) => Track(
    id: id,
    title: info.title,
    artist: info.artist,
    album: info.album,
    genre: info.genre,
    duration: duration,
    addedAt: addedAt,
    uri: uri,
    folder: folder,
    source: source,
    hasVideo: hasVideo,
    videoUri: videoUri,
  );

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// `3:42`, `1:02:05` 형식.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
