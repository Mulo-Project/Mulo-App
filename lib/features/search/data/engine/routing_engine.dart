import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/entities/subtitle_track.dart';
import '../../domain/entities/video_stream.dart';
import '../../domain/repositories/downloader_engine.dart';
import 'local_engine.dart';
import 'server_engine.dart';

/// 쓸 엔진을 고른다: 로컬 yt-dlp를 쓸 수 있으면(데스크톱) 로컬, 아니면 서버,
/// 둘 다 없으면 [EngineFailure.unavailable].
/// (설정에서 모드를 고르는 화면은 아직 없다.)
class RoutingDownloaderEngine implements DownloaderEngine {
  RoutingDownloaderEngine({this.local, this.server});

  final LocalEngine? local;
  final ServerEngine? server;
  bool _localReady = false;

  /// 로컬을 쓸 수 있다고 확인된 뒤에는 다시 확인하지 않는다. 못 쓰는 동안은
  /// 부를 때마다 확인한다 (설정에서 yt-dlp를 설치하면 바로 로컬로 바뀐다).
  Future<DownloaderEngine> _pick() async {
    final l = local;
    if (l != null && (_localReady || await l.isAvailable())) {
      _localReady = true;
      return l;
    }
    final s = server;
    if (s != null) return s;
    throw const EngineException(EngineFailure.unavailable);
  }

  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) async => (await _pick()).search(
    query,
    source: source,
    page: page,
    size: size,
    newest: newest,
  );

  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  }) async => (await _pick()).searchPlaylists(query, page: page, size: size);

  @override
  Future<MediaInfo> fetchInfo(String url) async =>
      (await _pick()).fetchInfo(url);

  @override
  Future<ChannelInfo> fetchChannel(String url) async =>
      (await _pick()).fetchChannel(url);

  @override
  Future<VideoStream> resolveVideoStream(
    String url, {
    int maxHeight = 360,
  }) async => (await _pick()).resolveVideoStream(url, maxHeight: maxHeight);

  @override
  Future<AudioStream> resolveAudioStream(
    String url, {
    bool refresh = false,
    String? audioLanguage,
  }) async => (await _pick()).resolveAudioStream(
    url,
    refresh: refresh,
    audioLanguage: audioLanguage,
  );

  @override
  Future<List<AudioLanguage>> fetchAudioLanguages(String url) async =>
      (await _pick()).fetchAudioLanguages(url);

  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) async =>
      (await _pick()).fetchSubtitles(url, preferLanguages: preferLanguages);
}
