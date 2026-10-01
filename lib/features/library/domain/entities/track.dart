/// 곡이 어디서 왔는지.
enum TrackSource { device, download }

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
