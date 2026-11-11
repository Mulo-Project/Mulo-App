import '../../../covers/domain/entities/cover_art.dart';
import '../entities/download_options.dart';

/// 영상 파일로 저장하기 요청 (원본 주소와 파일에 붙일 이름).
class VideoSaveRequest {
  const VideoSaveRequest({
    required this.url,
    required this.title,
    this.artist = '',
    this.album = '',
    this.genre = '',
    this.lyrics,
    this.cover,
    this.thumbnailUrl,
    this.color,
    this.maxHeight = 1080,
    this.folder = '',
    this.format = VideoFormat.mp4,
  });

  final String url;
  final String title;
  final String artist;
  final String album;
  final String genre;

  /// 파일 태그에 넣을 가사 글(.lrc 또는 일반 글). 없으면 null.
  final String? lyrics;

  /// 파일 태그에 넣을 커버(mp4만). 없으면 [thumbnailUrl]을 쓴다.
  final CoverArt? cover;
  final String? thumbnailUrl;

  /// 받은 영상의 커버 색(ARGB). 태그의 앱 전용 칸에 적는다.
  final int? color;

  /// 화질 상한(세로 픽셀). 이 이하에서 가장 좋은 화질을 받는다.
  final int maxHeight;

  /// 저장할 폴더 (`Movies` · `Download` 등). 비면 앱 기본 `Movies/Mulo`.
  final String folder;
  final VideoFormat format;
}

/// 영상을 받지 못했다. [message]는 원인 (로그 · 디버깅용).
class VideoSaveException implements Exception {
  const VideoSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 유튜브 등의 영상을 소리까지 합친 mp4 파일로 기기에 저장한다.
abstract interface class VideoSaveRepository {
  /// 이 빌드 · 기기에서 영상 파일을 저장할 수 있는지 (Android full 빌드만).
  Future<bool> isAvailable();

  /// 영상과 소리를 받아 mp4 한 파일로 합쳐 `Movies/Mulo`에 저장한다. 못 하면 [VideoSaveException].
  ///
  /// [onProgress]는 받는 진행률(0 ~ 1). 1에 닿은 뒤 합치기 · 저장이 이어질 수 있다.
  ///
  /// 저장한 영상의 재생 주소(Android `content://`)를 돌려준다.
  Future<String> save(
    VideoSaveRequest request, {
    void Function(double progress)? onProgress,
  });
}
