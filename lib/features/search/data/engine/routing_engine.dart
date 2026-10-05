import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/repositories/downloader_engine.dart';
import 'local_engine.dart';
import 'server_engine.dart';

/// 쓸 엔진을 고른다: 로컬 yt-dlp를 쓸 수 있으면(데스크톱) 로컬, 아니면 서버,
/// 둘 다 없으면 [EngineFailure.unavailable]. 고르는 건 한 번만 한다.
/// (설정에서 모드를 고르는 화면은 아직 없다.)
class RoutingDownloaderEngine implements DownloaderEngine {
  RoutingDownloaderEngine({this.local, this.server});

  final LocalEngine? local;
  final ServerEngine? server;
  Future<DownloaderEngine>? _picked;

  Future<DownloaderEngine> _pick() => _picked ??= _choose();

  Future<DownloaderEngine> _choose() async {
    final l = local;
    if (l != null && await l.isAvailable()) return l;
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
  }) async =>
      (await _pick()).search(query, source: source, page: page, size: size);

  @override
  Future<MediaInfo> fetchInfo(String url) async =>
      (await _pick()).fetchInfo(url);
}
