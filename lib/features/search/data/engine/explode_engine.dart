import 'dart:async';
import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/entities/subtitle_track.dart';
import '../../domain/entities/video_stream.dart';
import '../../domain/repositories/downloader_engine.dart';
import 'audio_format_policy.dart';

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

/// 유튜브 키워드 검색의 [page]쪽(0부터)을 읽는 함수. 못 읽으면 null.
typedef YoutubeSearchReader = Future<SearchPage?> Function(
  String query,
  int page,
  int size,
);

/// 유튜브 채널 주소로 채널 이미지 · 구독자 수를 읽는 함수. 못 읽으면 null.
typedef YoutubeChannelReader = Future<ChannelInfo?> Function(String url);

/// 유튜브 곡의 오디오 언어 트랙 목록을 읽는 함수.
typedef AudioLanguageReader = Future<List<AudioLanguage>> Function(
  String videoId,
);

/// 미리 듣기용 오디오 스트림 주소를 `youtube_explode_dart`로 먼저 읽는 엔진 덮개.
///
/// yt-dlp는 JS 실행기가 없는 환경(Android 등)에서 오디오 형식을 못 주는 경우가 있어서,
/// 유튜브 곡은 이 라이브러리가 먼저 읽고 못 읽으면 안쪽 엔진(yt-dlp · 서버)으로 넘긴다.
/// 나머지(검색 · 곡 정보 · 채널)는 그대로 안쪽 엔진이 한다.
class YoutubeExplodeEngine implements DownloaderEngine {
  YoutubeExplodeEngine(
    this._inner, {
    AudioStreamReader? reader,
    AudioLanguageReader? languageReader,
    MuxedVideoReader? videoReader,
    YoutubeSearchReader? searchReader,
    YoutubeChannelReader? channelReader,
  }) : _searchReader = searchReader ?? _ExplodeSearch().read,
       _channelReader = channelReader ?? _readChannelWithExplode,
       _reader = reader ?? _readWithExplode,
       _videoReader = videoReader ?? _readMuxedWithExplode,
       _languageReader = languageReader ?? _readLanguagesWithExplode;

  final DownloaderEngine _inner;
  final AudioStreamReader _reader;
  final AudioLanguageReader _languageReader;
  final MuxedVideoReader _videoReader;
  final YoutubeSearchReader _searchReader;
  final YoutubeChannelReader _channelReader;

  /// 유튜브 키워드 검색은 이 라이브러리가 먼저 한다 (yt-dlp는 폰에서 느리고, 다음 쪽을 부를 때마다
  /// 앞쪽까지 처음부터 다시 받는다). 최신순 · 다른 사이트이거나 못 읽으면 안쪽 엔진(yt-dlp · 서버)이 한다.
  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) async {
    if (source == SearchSource.youtube && !newest) {
      final clock = Stopwatch()..start();
      try {
        final found = await _searchReader(
          query,
          page,
          size,
        ).timeout(const Duration(seconds: 10));
        _log(
          'explode 검색 ${found == null ? '없음' : '${found.items.length}개'} '
          '쪽$page ${clock.elapsedMilliseconds}ms',
        );
        if (found != null && found.items.isNotEmpty) return found;
      } on Object catch (e) {
        _log('explode 검색 실패 ${clock.elapsedMilliseconds}ms: ${_oneLine(e)}');
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

  @override
  Future<MediaInfo> fetchInfo(String url) => _inner.fetchInfo(url);

  /// 유튜브 채널은 이 라이브러리가 먼저 읽는다 (yt-dlp 호출은 한 번에 하나씩이라 곡 정보와 줄을 서지 않는다).
  /// 못 읽으면 안쪽 엔진으로 넘긴다.
  @override
  Future<ChannelInfo> fetchChannel(String url) async {
    final clock = Stopwatch()..start();
    try {
      final info = await _channelReader(
        url,
      ).timeout(const Duration(seconds: 10));
      _log('explode 채널 ${info == null ? '없음' : '읽음'} ${clock.elapsedMilliseconds}ms');
      if (info != null) return info;
    } on Object catch (e) {
      _log('explode 채널 실패 ${clock.elapsedMilliseconds}ms: ${_oneLine(e)}');
    }
    return _inner.fetchChannel(url);
  }

  @override
  Future<VideoStream> resolveVideoStream(
    String url, {
    int maxHeight = 360,
  }) async {
    // 순수 Dart 라이브러리가 JS 풀이 없이 몇 초 안에 읽는다 (yt-dlp 기본 방식은 폰에서 20초쯤).
    // 소리가 든 형식을 못 읽으면 안쪽 엔진(yt-dlp)에 묻는다.
    final id = VideoId.parseVideoId(url);
    if (id != null) {
      final clock = Stopwatch()..start();
      try {
        final v = await _videoReader(
          id,
          maxHeight,
        ).timeout(const Duration(seconds: 15));
        _log('explode 영상 ${v == null ? '없음' : '읽음'} ${clock.elapsedMilliseconds}ms');
        if (v != null) return v;
      } on Object catch (e) {
        _log('explode 영상 실패 ${clock.elapsedMilliseconds}ms: ${_oneLine(e)}');
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
    Object? explodeError;
    if (id != null) {
      try {
        final stream = await _reader(id, language: audioLanguage);
        if (stream != null) return stream;
      } on Object catch (e) {
        // 이 라이브러리가 못 읽으면 안쪽 엔진으로 넘어간다.
        explodeError = e is EngineException ? e.message : e;
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
      if (explodeError == null) rethrow;
      throw EngineException(
        e.failure,
        'youtube_explode: ${_oneLine(explodeError)} | ${_oneLine(e.message)}',
      );
    }
  }

  /// 이 라이브러리가 먼저 읽고, 트랙이 없거나 못 읽으면 안쪽 엔진(yt-dlp)에 묻는다.
  @override
  Future<List<AudioLanguage>> fetchAudioLanguages(String url) async {
    final id = VideoId.parseVideoId(url);
    if (id != null) {
      try {
        final found = await _languageReader(id);
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

/// 유튜브 키워드 검색. 같은 검색어의 다음 쪽은 앞에서 읽은 결과 뒤에서 이어 읽는다
/// (매번 처음부터 다시 받지 않는다). 최근 검색 몇 개만 기억한다.
class _ExplodeSearch {
  final _sessions = <String, _SearchSession>{};

  Future<SearchPage?> read(String query, int page, int size) {
    var session = _sessions.remove(query);
    session ??= _SearchSession(query);
    _sessions[query] = session; // 가장 최근 것이 맨 뒤
    while (_sessions.length > 3) {
      _sessions.remove(_sessions.keys.first)?.close();
    }
    return session.page(page, size);
  }
}

class _SearchSession {
  _SearchSession(this.query);

  final String query;
  final _yt = YoutubeExplode();
  final _all = <MediaHit>[];
  final _seen = <String>{};
  SearchList? _last;
  var _started = false;
  var _done = false;
  Future<void> _busy = Future.value();

  void close() => _yt.close();

  /// 같은 검색의 요청이 겹쳐도 차례로 읽는다 (같은 쪽을 두 번 넘기지 않게).
  Future<SearchPage?> page(int page, int size) {
    final run = _busy.then((_) => _page(page, size));
    _busy = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<SearchPage?> _page(int page, int size) async {
    final want = (page + 1) * size;
    while (_all.length < want && !_done) {
      final SearchList? list;
      if (!_started) {
        list = await _yt.search.searchContent(
          query,
          filter: TypeFilters.video,
        );
        _started = true;
      } else {
        list = await _last?.nextPage();
      }
      if (list == null) {
        _done = true;
        break;
      }
      _last = list;
      for (final r in list) {
        if (r is! SearchVideo || !_seen.add(r.id.value)) continue;
        _all.add(_hitOf(r));
      }
      if (list.isEmpty) _done = true;
    }
    final start = page * size;
    final end = _all.length < want ? _all.length : want;
    return SearchPage(
      items: start >= end ? const [] : _all.sublist(start, end),
      hasNext: _all.length > end || !_done,
    );
  }
}

/// 검색 결과 한 줄 → 목록 항목. 길이를 모르는 라이브 · 예정 방송은 [MediaHit.isLive].
MediaHit _hitOf(SearchVideo r) {
  final id = r.id.value;
  final duration = _parseClock(r.duration);
  return MediaHit(
    id: id,
    title: r.title,
    url: 'https://www.youtube.com/watch?v=$id',
    uploader: r.author,
    duration: duration,
    thumbnailUrl: r.thumbnails.isEmpty
        ? 'https://i.ytimg.com/vi/$id/hqdefault.jpg'
        : r.thumbnails.last.url.toString(),
    channelUrl: r.channelId.isEmpty
        ? null
        : 'https://www.youtube.com/channel/${r.channelId}',
    viewCount: r.isLive ? null : r.viewCount,
    description: r.description,
    isLive: r.isLive || duration == null,
  );
}

/// `3:45` · `1:02:03` → 길이. 읽을 수 없으면 null.
Duration? _parseClock(String text) {
  final parts = text.trim().split(':');
  if (text.trim().isEmpty || parts.length > 3) return null;
  var seconds = 0;
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null) return null;
    seconds = seconds * 60 + n;
  }
  return Duration(seconds: seconds);
}

/// 유튜브 채널 주소(`/channel/…` · `/@…` · `/user/…`)로 채널 이미지 · 구독자 수를 읽는다.
/// 다른 모양의 주소이거나 유튜브가 아니면 null.
Future<ChannelInfo?> _readChannelWithExplode(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (host != 'youtube.com' && !host.endsWith('.youtube.com')) return null;
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segs.isEmpty) return null;
  final yt = YoutubeExplode();
  try {
    final Channel channel;
    if (segs.first.startsWith('@')) {
      channel = await yt.channels.getByHandle(segs.first);
    } else if (segs.length >= 2 && segs.first == 'channel') {
      channel = await yt.channels.get(segs[1]);
    } else if (segs.length >= 2 && segs.first == 'user') {
      channel = await yt.channels.getByUsername(segs[1]);
    } else {
      return null;
    }
    final logo = channel.logoUrl.isEmpty ? null : channel.logoUrl;
    // 아무것도 못 읽었으면 안쪽 엔진에 맡긴다.
    if (logo == null && channel.subscribersCount == null) return null;
    return ChannelInfo(thumbnailUrl: logo, subscriberCount: channel.subscribersCount);
  } finally {
    yt.close();
  }
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

/// 클라이언트를 차례로 써 보며 "실제로 끝까지 받을 수 있는" 오디오 주소를 읽는다.
///
/// 클라이언트마다 주소의 허용 조건이 달라(예: PO 토큰 없는 안드로이드 주소는 앞 일부만 주고 403)
/// 주소를 읽은 것만으로는 재생된다고 할 수 없다. 그래서 파일 중간 구간을 실제로 요청해 보고(probe)
/// 206이 오는 클라이언트의 주소를 쓴다. 모두 실패하면 읽은 주소 중 첫째를 그대로 돌려준다.
Future<AudioStream?> _readWithExplode(
  String videoId, {
  String? language,
}) async {
  final yt = YoutubeExplode();
  final errors = <String>[];
  AudioStream? firstReadable;
  try {
    for (final client in [
      _visionOs,
      YoutubeApiClient.androidVr,
      YoutubeApiClient.androidSdkless,
    ]) {
      final List<AudioOnlyStreamInfo> ordered;
      try {
        final manifest = await yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [client],
        );
        ordered = _orderAudio(
          manifest.audioOnly
              .where(
                (s) =>
                    language == null ||
                    (s.audioTrack != null &&
                        audioLanguageId(s.audioTrack!.id) == language),
              )
              .toList(),
        );
      } on Object catch (e) {
        errors.add(_oneLine(e).split(' / ').first);
        continue;
      }
      if (ordered.isEmpty) continue;
      final stream = _toStream(ordered.first, [
        for (final s in ordered.skip(1).take(3)) _toStream(s),
      ]);
      firstReadable ??= stream;
      if (await _canReadMiddle(ordered.first)) return stream;
      errors.add('${ordered.first.url.queryParameters['c']}: 구간 403');
    }
    if (firstReadable != null) return firstReadable;
    throw EngineException(EngineFailure.failed, errors.join(' | '));
  } on EngineException {
    rethrow;
  } on Object catch (e) {
    throw EngineException(EngineFailure.failed, '$e');
  } finally {
    yt.close();
  }
}

/// 영상 주소 하나. visionOS 클라이언트가 소리가 든 형식을 주면 그것(한 플레이어로 틀 수 있다),
/// 아니면 [maxHeight] 이하 mp4 영상 전용 형식 가운데 가장 큰 것. 못 읽는 주소(구간 403)는 거르고, 없으면 null.
Future<VideoStream?> _readMuxedWithExplode(String videoId, int maxHeight) async {
  final yt = YoutubeExplode();
  try {
    final StreamManifest manifest;
    try {
      manifest = await yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [_visionOs],
      );
    } on Object catch (e) {
      _log('explode 영상: visionOS 읽기 실패 ${_oneLine(e)}');
      return null;
    }
    final muxed = manifest.muxed
        .where((s) => s.videoResolution.height <= maxHeight)
        .toList()
      ..sort(
        (a, b) => b.videoResolution.height.compareTo(a.videoResolution.height),
      );
    final only = manifest.videoOnly
        .where(
          (s) =>
              s.container == StreamContainer.mp4 &&
              s.videoResolution.height <= maxHeight,
        )
        .toList()
      ..sort(
        (a, b) => b.videoResolution.height.compareTo(a.videoResolution.height),
      );
    // 소리 든 형식은 360p까지라, 고른 화질이 그보다 높아 더 큰 영상 전용 형식이 있으면 그쪽을 쓴다
    // (같거나 없으면 소리 든 형식: 한 플레이어로 바로 튼다).
    final StreamInfo? best;
    var isMuxed = false;
    if (muxed.isNotEmpty &&
        (only.isEmpty ||
            only.first.videoResolution.height <=
                muxed.first.videoResolution.height)) {
      best = muxed.first;
      isMuxed = true;
    } else {
      best = only.isEmpty ? null : only.first;
    }
    if (best == null) {
      _log('explode 영상: visionOS에 쓸 영상 형식 없음');
      return null;
    }
    if (!await _canReadMiddle(best)) {
      _log('explode 영상: ${best.url.queryParameters['c']} 구간 403');
      return null;
    }
    _log('explode 영상 형식 ${best.tag} muxed=$isMuxed');
    return VideoStream(
      url: best.url.toString(),
      headers: _toStream(best).headers,
      muxed: isMuxed,
    );
  } finally {
    yt.close();
  }
}

/// 클라이언트를 차례로 써 보며 오디오 언어 트랙이 둘 이상 담긴 것을 찾는다.
Future<List<AudioLanguage>> _readLanguagesWithExplode(String videoId) async {
  final yt = YoutubeExplode();
  try {
    for (final client in [
      _visionOs,
      YoutubeApiClient.androidVr,
      YoutubeApiClient.androidSdkless,
    ]) {
      try {
        final manifest = await yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [client],
        );
        final byId = <String, AudioLanguage>{};
        for (final s in manifest.audioOnly) {
          final track = s.audioTrack;
          if (track == null) continue;
          final id = audioLanguageId(track.id);
          byId.putIfAbsent(
            id,
            () => AudioLanguage(
              id: id,
              name: track.displayName,
              isDefault: track.audioIsDefault,
            ),
          );
        }
        if (byId.length > 1) return byId.values.toList();
      } on Object {
        continue;
      }
    }
    return const [];
  } finally {
    yt.close();
  }
}

/// 정책 형식을 먼저, 그다음 나머지 (비트레이트 높은 순). 앞의 것이 안 열리면 플레이어가 차례로 써 본다.
List<AudioOnlyStreamInfo> _orderAudio(List<AudioOnlyStreamInfo> audio) {
  final preferred = preferredAudioFormat() == AudioFormat.m4a
      ? StreamContainer.mp4
      : StreamContainer.webM;
  return audio..sort((a, b) {
    final byFormat = (b.container == preferred ? 1 : 0).compareTo(
      a.container == preferred ? 1 : 0,
    );
    return byFormat != 0 ? byFormat : b.bitrate.compareTo(a.bitrate);
  });
}

AudioStream _toStream(StreamInfo s, [List<AudioStream> rest = const []]) =>
    AudioStream(
      url: s.url.toString(),
      headers: {
        'user-agent': switch (s.url.queryParameters['c']) {
          'ANDROID' => _androidUserAgent,
          'ANDROID_VR' => _androidVrUserAgent,
          'VISIONOS' => _visionOsUserAgent,
          _ => _userAgent,
        },
      },
      fallbacks: rest,
    );

/// 파일 가운데 1KB를 실제로 요청해 206이 오는지 본다 (못 받는 주소를 미리 걸러내려고).
Future<bool> _canReadMiddle(StreamInfo s) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  try {
    final total = s.size.totalBytes;
    final from = total > 4096 ? total ~/ 2 : 0;
    final req = await client.getUrl(s.url);
    _toStream(s).headers.forEach(req.headers.set);
    req.headers.set('range', 'bytes=$from-${from + 1023}');
    final resp = await req.close().timeout(const Duration(seconds: 8));
    await resp.drain<void>();
    return resp.statusCode == 206 || resp.statusCode == 200;
  } on Object {
    // 확인 자체가 안 되면(네트워크 등) 거르지 않고 쓴다.
    return true;
  } finally {
    client.close(force: true);
  }
}

const _visionOsUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 '
    '(KHTML, like Gecko) Version/26.0 Safari/605.1.15';

/// yt-dlp의 visionos 클라이언트와 같은 설정 (JS 실행기 · PO 토큰 없이 전체 구간 주소를 준다).
const _visionOs = YoutubeApiClient({
  'context': {
    'client': {
      'clientName': 'VISIONOS',
      'clientVersion': '1.02',
      'deviceMake': 'Apple',
      'deviceModel': 'RealityDevice17,1',
      'userAgent': _visionOsUserAgent,
      'osName': 'visionOS',
      'osVersion': '26.5.23O471',
      'hl': 'en',
      'timeZone': 'UTC',
      'utcOffsetMinutes': 0,
    },
  },
}, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

const _androidVrUserAgent =
    'com.google.android.apps.youtube.vr.oculus/1.62.27 '
    '(Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip';

const _androidUserAgent =
    'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip';

const _userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';
