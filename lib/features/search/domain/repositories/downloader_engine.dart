import '../entities/audio_stream.dart';
import '../entities/media_info.dart';
import '../entities/search_source.dart';

/// 음원 사이트에서 찾고 받는 엔진 (서버 모드 `ServerEngine` / 로컬 모드 `LocalEngine`).
/// 지금은 검색 · 곡 정보만 있다. 받기는 다음 작업에서 더한다.
///
/// 실패는 [EngineException]으로 던진다.
abstract interface class DownloaderEngine {
  /// 키워드 검색. [page]는 0부터. [newest]면 올린 날 최신 순으로 찾는다.
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  });

  /// 키워드로 유튜브 재생목록을 찾는다. [page]는 0부터.
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  });

  /// URL로 곡 또는 재생목록 정보를 가져온다.
  Future<MediaInfo> fetchInfo(String url);

  /// 채널 주소로 채널 이미지 · 구독자 수를 가져온다. 알 수 없으면 [EngineException]
  /// (`unavailable` 포함)을 던진다.
  Future<ChannelInfo> fetchChannel(String url);

  /// 곡을 받지 않고 바로 들을 수 있는 오디오 스트림 주소를 알아낸다 (미리 듣기).
  /// 쓸 수 없는 엔진은 [EngineException] (`unavailable`)을 던진다.
  ///
  /// [refresh]가 true면 기억해 둔 주소를 쓰지 않고 새로 읽는다 (받다가 403 등으로 막혔을 때 다시 읽기).
  Future<AudioStream> resolveAudioStream(String url, {bool refresh = false});
}
