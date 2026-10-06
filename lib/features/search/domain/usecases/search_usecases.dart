import '../../../../core/usecase/usecase.dart';
import '../entities/media_info.dart';
import '../entities/search_source.dart';
import '../repositories/downloader_engine.dart';

class SearchParams {
  const SearchParams(this.query, this.source, {this.page = 0});

  final String query;
  final SearchSource source;
  final int page;
}

/// 키워드로 찾기 (상세 기능: 키워드 검색 #2).
class SearchTracks implements UseCase<SearchPage, SearchParams> {
  const SearchTracks(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<SearchPage> call(SearchParams p) =>
      _engine.search(p.query.trim(), source: p.source, page: p.page);
}

/// URL로 곡 · 재생목록 정보 불러오기 (상세 기능: URL로 곡 정보 불러오기 #1).
class FetchMediaInfo implements UseCase<MediaInfo, String> {
  const FetchMediaInfo(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<MediaInfo> call(String url) => _engine.fetchInfo(url.trim());
}
