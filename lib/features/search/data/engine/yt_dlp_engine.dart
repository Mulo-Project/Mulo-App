import '../../../engine/data/native_yt_dlp.dart';
import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/entities/subtitle_track.dart';
import '../../domain/entities/video_stream.dart';
import '../../domain/repositories/downloader_engine.dart';

/// 로컬 모드(Android full): 네이티브 yt-dlp 엔진(`YtDlpEngine`)이 찾고 읽는다.
/// yt-dlp 인자 · JSON 해석 · 자막 · 실행 줄은 모두 네이티브에 있고, 여기서는 받은 값을 모델에 담기만 한다.
class YtDlpEngine implements DownloaderEngine {
  YtDlpEngine(this._native);

  final NativeYtDlp _native;

  /// 이 빌드에 yt-dlp가 들어 있는지.
  Future<bool> isAvailable() => _native.isAvailable();

  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) async {
    // 최신순은 날짜 순 검색(ytsearchdate · nicosearchdate)이 있는 사이트만 쓴다.
    final prefix = newest && source.supportsNewest
        ? '${source.searchKey}date'
        : source.searchKey;
    final r = await _native.search(prefix, query, page, size);
    return SearchPage(items: _hits(r['items']), hasNext: _bool(r['hasNext']));
  }

  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    final r = await _native.searchPlaylists(query, page, size);
    return PlaylistSearchPage(
      items: [for (final m in _maps(r['items'])) _playlistHit(m)],
      hasNext: _bool(r['hasNext']),
    );
  }

  @override
  Future<MediaInfo> fetchFullInfo(String url) => fetchInfo(url);

  @override
  Future<MediaInfo> fetchInfo(String url) async {
    final r = await _native.info(url);
    if (r['type'] == 'playlist') {
      return PlaylistInfo(
        title: r['title'] as String? ?? '',
        entries: _hits(r['entries']),
        thumbnailUrl: r['thumbnail'] as String?,
      );
    }
    return VideoInfo(_hit(r['hit']! as Map<Object?, Object?>));
  }

  @override
  Future<ChannelInfo> fetchChannel(String url) async {
    final r = await _native.channel(url);
    return ChannelInfo(
      thumbnailUrl: r['thumbnail'] as String?,
      subscriberCount: (r['subscriberCount'] as num?)?.toInt(),
    );
  }

  @override
  Future<AudioStream> resolveAudioStream(
    String url, {
    bool refresh = false,
    String? audioLanguage,
  }) async {
    final r = await _native.audio(url, audioLanguage);
    return AudioStream(url: r['url']! as String, headers: _headers(r));
  }

  @override
  Future<VideoStream> resolveVideoStream(
    String url, {
    int maxHeight = 360,
  }) async {
    final r = await _native.video(url, maxHeight);
    return VideoStream(
      url: r['url']! as String,
      muxed: _bool(r['muxed']),
      headers: _headers(r),
    );
  }

  @override
  Future<void> warmUp() async {}

  @override
  Future<List<AudioLanguage>> fetchAudioLanguages(String url) async => [
    for (final m in await _native.audioLanguages(url))
      AudioLanguage(
        id: m['id']! as String,
        name: m['name'] as String? ?? m['id']! as String,
        isDefault: _bool(m['isDefault']),
      ),
  ];

  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) async {
    final r = await _native.subtitles(url, preferLanguages);
    if (r == null) return null;
    return SubtitleTrack(
      language: r['language']! as String,
      automatic: _bool(r['automatic']),
      cues: [
        for (final c in _maps(r['cues']))
          SubtitleCue(
            Duration(milliseconds: (c['ms']! as num).toInt()),
            c['text']! as String,
          ),
      ],
    );
  }

  bool _bool(Object? v) => v == true;

  List<Map<Object?, Object?>> _maps(Object? v) => [
    for (final e in (v as List<Object?>? ?? const []))
      e! as Map<Object?, Object?>,
  ];

  List<String> _strings(Object? v) => [
    for (final e in (v as List<Object?>? ?? const []))
      if (e is String) e,
  ];

  Map<String, String> _headers(Map<Object?, Object?> r) => {
    for (final e in (r['headers'] as Map<Object?, Object?>? ?? const {}).entries)
      e.key! as String: e.value! as String,
  };

  List<MediaHit> _hits(Object? v) => [for (final m in _maps(v)) _hit(m)];

  PlaylistHit _playlistHit(Map<Object?, Object?> m) => PlaylistHit(
    id: m['id']! as String,
    title: m['title'] as String? ?? '',
    url: m['url']! as String,
    channel: m['channel'] as String? ?? '',
    thumbnailUrl: m['thumbnail'] as String?,
    trackCount: (m['trackCount'] as num?)?.toInt(),
  );

  MediaHit _hit(Map<Object?, Object?> m) {
    final seconds = (m['seconds'] as num?)?.toInt();
    return MediaHit(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      url: m['url']! as String,
      uploader: m['uploader'] as String? ?? '',
      duration: seconds == null ? null : Duration(seconds: seconds),
      thumbnailUrl: m['thumbnail'] as String?,
      categories: _strings(m['categories']),
      channelUrl: m['channelUrl'] as String?,
      viewCount: (m['views'] as num?)?.toInt(),
      uploadedAt: DateTime.tryParse(m['uploadDate'] as String? ?? ''),
      description: m['description'] as String? ?? '',
      likeCount: (m['likes'] as num?)?.toInt(),
      subscriberCount: (m['subscribers'] as num?)?.toInt(),
      creators: _strings(m['creators']),
      subtitleLangs: _strings(m['subtitleLangs']),
      autoSubtitleLangs: _strings(m['autoSubtitleLangs']),
      album: m['album'] as String? ?? '',
      isLive: _bool(m['isLive']),
    );
  }
}
