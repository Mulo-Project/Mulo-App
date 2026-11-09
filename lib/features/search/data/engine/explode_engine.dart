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
  }) : _reader = reader ?? _readWithExplode,
       _languageReader = languageReader ?? _readLanguagesWithExplode;

  final DownloaderEngine _inner;
  final AudioStreamReader _reader;
  final AudioLanguageReader _languageReader;

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

  @override
  Future<ChannelInfo> fetchChannel(String url) => _inner.fetchChannel(url);

  @override
  Future<VideoStream> resolveVideoStream(String url, {int maxHeight = 360}) =>
      _inner.resolveVideoStream(url, maxHeight: maxHeight);

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
Future<bool> _canReadMiddle(AudioOnlyStreamInfo s) async {
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
