import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/repositories/downloader_engine.dart';

/// 유튜브 곡의 오디오 스트림 주소를 읽는 함수. 못 읽으면 null.
typedef AudioStreamReader = Future<AudioStream?> Function(String videoId);

/// 미리 듣기용 오디오 스트림 주소를 `youtube_explode_dart`로 먼저 읽는 엔진 덮개.
///
/// yt-dlp는 JS 실행기가 없는 환경(Android 등)에서 오디오 형식을 못 주는 경우가 있어서,
/// 유튜브 곡은 이 라이브러리가 먼저 읽고 못 읽으면 안쪽 엔진(yt-dlp · 서버)으로 넘긴다.
/// 나머지(검색 · 곡 정보 · 채널)는 그대로 안쪽 엔진이 한다.
class YoutubeExplodeEngine implements DownloaderEngine {
  YoutubeExplodeEngine(this._inner, {AudioStreamReader? reader})
    : _reader = reader ?? _readWithExplode;

  final DownloaderEngine _inner;
  final AudioStreamReader _reader;

  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) => _inner.search(
    query,
    source: source,
    page: page,
    size: size,
    newest: newest,
  );

  @override
  Future<MediaInfo> fetchInfo(String url) => _inner.fetchInfo(url);

  @override
  Future<ChannelInfo> fetchChannel(String url) => _inner.fetchChannel(url);

  @override
  Future<AudioStream> resolveAudioStream(String url) async {
    final id = VideoId.parseVideoId(url);
    if (id != null) {
      try {
        final stream = await _reader(id);
        if (stream != null) return stream;
      } on Object {
        // 이 라이브러리가 못 읽으면 안쪽 엔진으로 넘어간다.
      }
    }
    return _inner.resolveAudioStream(url);
  }
}

/// 안드로이드 · 기본 클라이언트 순으로 m4a(AAC) 오디오를 먼저 골라 주소를 읽는다.
/// (macOS의 just_audio는 webm/opus를 못 푼다.)
Future<AudioStream?> _readWithExplode(String videoId) async {
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streamsClient.getManifest(
      videoId,
      ytClients: [YoutubeApiClient.androidVr, YoutubeApiClient.androidSdkless],
    );
    final audio = manifest.audioOnly;
    if (audio.isEmpty) return null;
    final m4a = audio.where((s) => s.container == StreamContainer.mp4);
    final best = (m4a.isNotEmpty ? m4a : audio).toList()
      ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
    return AudioStream(
      url: best.first.url.toString(),
      headers: const {'user-agent': _userAgent},
    );
  } on Object catch (e) {
    throw EngineException(EngineFailure.failed, '$e');
  } finally {
    yt.close();
  }
}

const _userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';
