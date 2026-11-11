import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/entities/subtitle_track.dart';
import '../../domain/entities/video_stream.dart';
import '../../domain/repositories/downloader_engine.dart';

/// 곡 · 채널 정보 · 스트림 주소 · 자막을 잠깐 기억해 같은 주소를 다시 읽지 않는 엔진 덮개.
/// 같은 곡을 다시 열어도 빠르다.
/// 읽는 중인 요청도 함께 쓰므로 같은 주소를 동시에 두 번 부르지 않는다.
/// 실패는 기억하지 않는다. 검색은 항상 새로 한다.
class CachedDownloaderEngine implements DownloaderEngine {
  CachedDownloaderEngine(
    this._inner, {
    this.ttl = const Duration(minutes: 15),
    this.infoTtl,
    this.maxEntries = 300,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DownloaderEngine _inner;
  /// 곡 · 채널 정보 · 오디오 언어를 기억하는 시간 (스트림 주소는 곧 만료돼서 [ttl]로 짧게). 없으면 [ttl].
  final Duration? infoTtl;
  final Duration ttl;
  final int maxEntries;
  final DateTime Function() _now;

  final _infos = <String, _Entry<MediaInfo>>{};
  final _channels = <String, _Entry<ChannelInfo>>{};
  final _streams = <String, _Entry<AudioStream>>{};
  final _videoStreams = <String, _Entry<VideoStream>>{};
  final _subtitles = <String, _Entry<SubtitleTrack?>>{};
  final _languages = <String, _Entry<List<AudioLanguage>>>{};

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
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  }) => _inner.searchPlaylists(query, page: page, size: size);

  @override
  Future<MediaInfo> fetchInfo(String url) =>
      _cached(_infos, url, () => _inner.fetchInfo(url), infoTtl);

  @override
  Future<ChannelInfo> fetchChannel(String url) =>
      _cached(_channels, url, () => _inner.fetchChannel(url), infoTtl);

  @override
  Future<AudioStream> resolveAudioStream(
    String url, {
    bool refresh = false,
    String? audioLanguage,
  }) {
    // 같은 곡이라도 오디오 언어가 다르면 다른 주소다.
    final key = audioLanguage == null ? url : '$url|$audioLanguage';
    if (refresh) _streams.remove(key);
    return _cached(
      _streams,
      key,
      () => _inner.resolveAudioStream(
        url,
        refresh: refresh,
        audioLanguage: audioLanguage,
      ),
    );
  }

  @override
  Future<VideoStream> resolveVideoStream(String url, {int maxHeight = 360}) =>
      _cached(
        _videoStreams,
        '$url|$maxHeight',
        () => _inner.resolveVideoStream(url, maxHeight: maxHeight),
      );

  @override
  Future<void> warmUp() => _inner.warmUp();

  @override
  Future<List<AudioLanguage>> fetchAudioLanguages(String url) =>
      _cached(_languages, url, () => _inner.fetchAudioLanguages(url), infoTtl);

  Future<T> _cached<T>(
    Map<String, _Entry<T>> cache,
    String key,
    Future<T> Function() load, [
    Duration? keepFor,
  ]) {
    final hit = cache[key];
    if (hit != null && _now().difference(hit.at) < (keepFor ?? ttl)) {
      return hit.value;
    }

    final value = load();
    cache[key] = _Entry(value, _now());
    // 실패는 기억하지 않는다 (다음에 다시 시도).
    value.then<void>(
      (_) {},
      onError: (Object _) {
        if (cache[key]?.value == value) cache.remove(key);
      },
    );
    // 오래된 것부터 버린다 (Map은 넣은 순서를 지킨다).
    while (cache.length > maxEntries) {
      cache.remove(cache.keys.first);
    }
    return value;
  }

  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) => _cached(
    _subtitles,
    // 같은 곡이라도 우선하는 언어가 다르면 다른 자막이다.
    '$url|${preferLanguages.join(',')}',
    () => _inner.fetchSubtitles(url, preferLanguages: preferLanguages),
  );
}

class _Entry<T> {
  const _Entry(this.value, this.at);

  final Future<T> value;
  final DateTime at;
}
