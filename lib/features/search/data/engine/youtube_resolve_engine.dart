import 'dart:async';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/entities/subtitle_track.dart';
import '../../domain/entities/video_stream.dart';
import '../../domain/repositories/downloader_engine.dart';

/// 유튜브 곡의 오디오 스트림 주소를 읽는 함수. 못 읽으면 null.
typedef AudioStreamReader = Future<AudioStream?> Function(
  String videoId, {
  String? language,
});

/// 유튜브 영상의 소리가 든 영상 스트림 주소를 읽는 함수. 못 읽으면 null.
typedef MuxedVideoReader = Future<VideoStream?> Function(
  String videoId,
  int maxHeight,
);

/// 유튜브 곡의 오디오 언어 트랙 목록을 읽는 함수.
typedef AudioLanguageReader = Future<List<AudioLanguage>> Function(
  String videoId,
);

/// 유튜브 키워드 검색의 [page]쪽(0부터)을 읽는 함수.
typedef YoutubeSearchReader = Future<SearchPage> Function(
  String query,
  int page,
  int size,
);

/// 유튜브 재생목록 id로 곡 목록을 읽는 함수.
typedef YoutubePlaylistReader = Future<PlaylistInfo> Function(
  String playlistId,
);

/// 유튜브 곡의 재생 주소(소리 · 영상 · 오디오 언어)를 [reader] 등으로 먼저 읽는 엔진 덮개.
///
/// 읽기는 Android 네이티브(`NativeYoutubeResolver`)가 한다 (D-162). 못 읽으면 안쪽 엔진(yt-dlp · 서버)으로 넘긴다.
/// 나머지(검색 · 곡 정보 · 채널)는 그대로 안쪽 엔진이 한다.
class YoutubeResolveEngine implements DownloaderEngine {
  YoutubeResolveEngine(
    this._inner, {
    required this.reader,
    required this.languageReader,
    required this.videoReader,
    this.searchReader,
    this.playlistReader,
    this.warmUpReader,
  });

  final DownloaderEngine _inner;
  final AudioStreamReader reader;
  final AudioLanguageReader languageReader;
  final MuxedVideoReader videoReader;

  /// 네이티브 검색 · 재생목록 읽기 (없으면 안쪽 엔진이 한다).
  final YoutubeSearchReader? searchReader;
  final YoutubePlaylistReader? playlistReader;

  /// 네이티브가 유튜브와 연결을 미리 열게 한다 (없으면 안쪽 엔진).
  final Future<void> Function()? warmUpReader;

  @override
  Future<void> warmUp() async {
    final warm = warmUpReader;
    if (warm == null) return _inner.warmUp();
    try {
      await warm();
    } on Object {
      // 미리 열기는 실패해도 괜찮다.
    }
  }

  /// 유튜브 키워드 검색은 네이티브가 먼저 읽는다. 최신순 · 다른 사이트이거나 못 읽으면 안쪽 엔진(yt-dlp · 서버).
  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) async {
    final read = searchReader;
    if (read != null && source == SearchSource.youtube && !newest) {
      final clock = Stopwatch()..start();
      try {
        final found = await read(
          query,
          page,
          size,
        ).timeout(const Duration(seconds: 15));
        _log('검색 쪽$page ${found.items.length}개 ${clock.elapsedMilliseconds}ms');
        return found;
      } on Object catch (e) {
        _log('검색 실패 ${clock.elapsedMilliseconds}ms: ${_oneLine(e)}');
        // 못 읽으면 안쪽 엔진으로 넘어간다.
      }
    }
    return _inner.search(
      query,
      source: source,
      page: page,
      size: size,
      newest: newest,
    );
  }

  /// 안쪽 엔진(yt-dlp · 서버)이 채널 이름까지 알려 주므로 먼저 묻고, 쓸 수 없거나
  /// 실패하면 이 라이브러리로 찾는다 (채널 이름은 모른다).
  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      return await _inner.searchPlaylists(query, page: page, size: size);
    } on EngineException catch (e) {
      if (e.failure == EngineFailure.network ||
          e.failure == EngineFailure.timeout) {
        rethrow;
      }
      try {
        // 이 라이브러리는 응답이 없으면 끝없이 기다리므로 시간을 둔다.
        return await _playlistSearch(
          query,
          page,
          size,
        ).timeout(const Duration(seconds: 30));
      } on TimeoutException {
        throw const EngineException(EngineFailure.timeout, 'timeout');
      } on Object {
        throw e;
      }
    }
  }

  /// 유튜브 재생목록 주소(`/playlist?list=…`)는 네이티브가 곡 목록을 먼저 읽는다. 곡 하나 · 다른 주소 · 실패는 안쪽 엔진.
  @override
  Future<MediaInfo> fetchInfo(String url) async {
    final read = playlistReader;
    final listId = read == null ? null : youtubePlaylistIdOf(url);
    if (read != null && listId != null) {
      final clock = Stopwatch()..start();
      try {
        final info = await read(listId).timeout(const Duration(seconds: 60));
        _log('재생목록 ${info.entries.length}곡 ${clock.elapsedMilliseconds}ms');
        return info;
      } on Object catch (e) {
        _log('재생목록 실패 ${clock.elapsedMilliseconds}ms: ${_oneLine(e)}');
      }
    }
    return _inner.fetchInfo(url);
  }

  @override
  Future<ChannelInfo> fetchChannel(String url) => _inner.fetchChannel(url);

  @override
  Future<VideoStream> resolveVideoStream(
    String url, {
    int maxHeight = 360,
  }) async {
    // 네이티브가 JS 풀이 없이 몇 초 안에 읽는다 (yt-dlp 기본 방식은 폰에서 20초쯤).
    // 소리가 든 형식을 못 읽으면 안쪽 엔진(yt-dlp)에 묻는다.
    final id = VideoId.parseVideoId(url);
    if (id != null) {
      final clock = Stopwatch()..start();
      try {
        final v = await videoReader(
          id,
          maxHeight,
        ).timeout(const Duration(seconds: 15));
        _log(
          '영상 읽기 ${v == null ? '없음' : '읽음'} ${clock.elapsedMilliseconds}ms',
        );
        if (v != null) return v;
      } on Object catch (e) {
        _log('영상 읽기 실패 ${clock.elapsedMilliseconds}ms: ${_oneLine(e)}');
        // 못 읽으면 안쪽 엔진으로 넘어간다.
      }
    }
    return _inner.resolveVideoStream(url, maxHeight: maxHeight);
  }

  @override
  Future<AudioStream> resolveAudioStream(
    String url, {
    bool refresh = false,
    String? audioLanguage,
  }) async {
    final id = VideoId.parseVideoId(url);
    Object? nativeError;
    if (id != null) {
      final clock = Stopwatch()..start();
      try {
        final stream = await reader(id, language: audioLanguage);
        _log(
          '소리 읽기 ${stream == null ? '없음' : '읽음'} ${clock.elapsedMilliseconds}ms',
        );
        if (stream != null) return stream;
      } on Object catch (e) {
        _log('소리 읽기 실패 ${clock.elapsedMilliseconds}ms: ${_oneLine(e)}');
        // 못 읽으면 안쪽 엔진으로 넘어간다.
        nativeError = e is EngineException ? e.message : e;
      }
    }
    try {
      return await _inner.resolveAudioStream(
        url,
        refresh: refresh,
        audioLanguage: audioLanguage,
      );
    } on EngineException catch (e) {
      // 둘 다 못 읽었으면 두 까닭을 같이 알린다 (안내에 보여 원인을 알 수 있게).
      if (nativeError == null) rethrow;
      throw EngineException(
        e.failure,
        '네이티브: ${_oneLine(nativeError)} | ${_oneLine(e.message)}',
      );
    }
  }

  /// 네이티브가 먼저 읽고, 트랙이 없거나 못 읽으면 안쪽 엔진(yt-dlp)에 묻는다.
  @override
  Future<List<AudioLanguage>> fetchAudioLanguages(String url) async {
    final id = VideoId.parseVideoId(url);
    if (id != null) {
      try {
        final found = await languageReader(id);
        if (found.length > 1) return found;
      } on Object {
        // 못 읽으면 안쪽 엔진으로 넘어간다.
      }
    }
    return _inner.fetchAudioLanguages(url);
  }

  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) => _inner.fetchSubtitles(url, preferLanguages: preferLanguages);
}

/// 라이브러리의 재생목록 검색 (한 번에 20개라 필요한 만큼 다음 쪽을 넘겨 읽는다).
Future<PlaylistSearchPage> _playlistSearch(
  String query,
  int page,
  int size,
) async {
  final yt = YoutubeExplode();
  try {
    var list = await yt.search.searchContent(
      query,
      filter: TypeFilters.playlist,
    );
    final all = <PlaylistHit>[];
    final want = (page + 1) * size;
    while (true) {
      for (final r in list) {
        if (r is! SearchPlaylist) continue;
        final id = r.id.value;
        all.add(
          PlaylistHit(
            id: id,
            title: r.title,
            url: 'https://www.youtube.com/playlist?list=$id',
            thumbnailUrl: r.thumbnails.isEmpty
                ? null
                : r.thumbnails.last.url.toString(),
            trackCount: r.videoCount,
          ),
        );
      }
      if (all.length >= want) break;
      final next = await list.nextPage();
      if (next == null) break;
      list = next;
    }
    final start = page * size;
    final end = all.length < want ? all.length : want;
    return PlaylistSearchPage(
      items: start >= end ? const [] : all.sublist(start, end),
      hasNext: all.length > want,
    );
  } finally {
    yt.close();
  }
}

/// 유튜브 재생목록 주소(`youtube.com/playlist?list=…`)의 목록 id. 곡 하나를 가리키는 주소(`watch?v=…&list=…`)나
/// 유튜브가 아닌 주소는 null (그건 안쪽 엔진이 읽는다).
String? youtubePlaylistIdOf(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (host != 'youtube.com' && !host.endsWith('.youtube.com')) return null;
  if (uri.path != '/playlist') return null;
  final id = uri.queryParameters['list'];
  return id == null || id.isEmpty ? null : id;
}

/// 디버그 빌드에서 adb logcat(`flutter` 태그)으로 보인다.
void _log(String message) {
  assert(() {
    // ignore: avoid_print
    print('[MuloSearch] $message');
    return true;
  }());
}

String _oneLine(Object? o) => '$o'
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .join(' / ');
