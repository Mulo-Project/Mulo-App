import '../../../../core/usecase/usecase.dart';
import '../entities/media_info.dart';
import '../entities/search_source.dart';
import '../repositories/downloader_engine.dart';
import '../repositories/link_opener.dart';

class SearchParams {
  const SearchParams(
    this.query,
    this.source, {
    this.page = 0,
    this.newest = false,
  });

  final String query;
  final SearchSource source;
  final int page;

  /// 올린 날 최신 순으로 찾을지.
  final bool newest;
}

/// 키워드로 찾기 (상세 기능: 키워드 검색 #2).
class SearchTracks implements UseCase<SearchPage, SearchParams> {
  const SearchTracks(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<SearchPage> call(SearchParams p) => _engine.search(
    p.query.trim(),
    source: p.source,
    page: p.page,
    newest: p.newest,
  );
}

/// URL로 곡 · 재생목록 정보 불러오기 (상세 기능: URL로 곡 정보 불러오기 #1).
class FetchMediaInfo implements UseCase<MediaInfo, String> {
  const FetchMediaInfo(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<MediaInfo> call(String url) => _engine.fetchInfo(url.trim());
}

/// 채널 이미지 · 구독자 수 불러오기 (상세 보기).
class FetchChannelInfo implements UseCase<ChannelInfo, String> {
  const FetchChannelInfo(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<ChannelInfo> call(String url) => _engine.fetchChannel(url.trim());
}

/// 곡 · 채널 주소를 기기의 기본 앱으로 열기 (상세 보기에서 영상 보기 · 채널 보기).
class OpenLink implements UseCase<bool, String> {
  const OpenLink(this._opener);

  final LinkOpener _opener;

  @override
  Future<bool> call(String url) => _opener.open(url);
}
