import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/entities/subtitle_track.dart';
import '../../domain/repositories/downloader_engine.dart';
import 'audio_format_policy.dart';
import 'json_fields.dart';

/// 프로세스 실행 하나 (테스트에서 바꿔 끼운다).
typedef RunProcess =
    Future<({int exitCode, String stdout, String stderr})> Function(
      String executable,
      List<String> args,
    );

/// yt-dlp 한 번이 이 시간 안에 안 끝나면 멈춘 것으로 보고 프로세스를 끊는다 (검색 · 정보 읽기가 무한정 돌지 않게).
const ytDlpTimeout = Duration(seconds: 60);

Future<({int exitCode, String stdout, String stderr})> _defaultRun(
  String executable,
  List<String> args,
) async {
  final process = await Process.start(executable, args);
  final out = process.stdout
      .transform(const Utf8Decoder(allowMalformed: true))
      .join();
  final err = process.stderr
      .transform(const Utf8Decoder(allowMalformed: true))
      .join();
  try {
    final code = await process.exitCode.timeout(ytDlpTimeout);
    return (exitCode: code, stdout: await out, stderr: await err);
  } on TimeoutException {
    process.kill();
    rethrow;
  }
}

/// 로컬 모드: 이 기기에서 yt-dlp를 직접 실행해 찾는다 (데스크톱).
/// Android 로컬(full 빌드)은 아직 없다.
class LocalEngine implements DownloaderEngine {
  LocalEngine({
    Future<String> Function()? resolveExecutable,
    RunProcess? run,
    Future<Directory> Function()? makeTempDir,
  }) : _resolve = resolveExecutable ?? (() async => 'yt-dlp'),
       _run = run ?? _defaultRun,
       _makeTempDir =
           makeTempDir ?? (() => Directory.systemTemp.createTemp('mulo_sub_'));

  /// 실행할 yt-dlp 경로 (앱이 받은 것 또는 PATH의 `yt-dlp`).
  final Future<String> Function() _resolve;
  final RunProcess _run;
  final Future<Directory> Function() _makeTempDir;

  /// yt-dlp를 실행할 수 있는지 (`--version`).
  Future<bool> isAvailable() async {
    try {
      final r = await _run(await _resolve(), const ['--version']);
      return r.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) async {
    // 사이트 검색은 쪽 개념이 없어서 (page+1)*size개를 받아 해당 쪽만 자른다.
    final want = (page + 1) * size;
    // 최신순은 날짜 순 검색(ytsearchdate · nicosearchdate)이 있는 사이트만 쓴다.
    final prefix = newest && source.supportsNewest
        ? '${source.searchKey}date'
        : source.searchKey;
    final out = await _exec([
      '--flat-playlist',
      '--dump-json',
      '--no-warnings',
      '$prefix$want:$query',
    ]);
    final all = <MediaHit>[];
    for (final line in const LineSplitter().convert(out)) {
      if (line.trim().isEmpty) continue;
      final j = _decode(line);
      if (j != null) all.add(_hit(j));
    }
    final start = page * size;
    return SearchPage(
      items: start >= all.length ? const [] : all.sublist(start),
      hasNext: all.length >= want,
    );
  }

  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    // 유튜브 검색 결과 쪽의 "재생목록" 필터 주소를 목록으로 읽는다.
    final want = (page + 1) * size;
    final out = await _exec([
      '--flat-playlist',
      '--dump-json',
      '--no-warnings',
      '--playlist-end',
      '$want',
      Uri.https('www.youtube.com', '/results', {
        'search_query': query,
        'sp': 'EgIQAw%3D%3D',
      }).toString(),
    ]);
    final all = <PlaylistHit>[];
    for (final line in const LineSplitter().convert(out)) {
      if (line.trim().isEmpty) continue;
      final j = _decode(line);
      final hit = j == null ? null : _playlistHit(j);
      if (hit != null) all.add(hit);
    }
    final start = page * size;
    return PlaylistSearchPage(
      items: start >= all.length ? const [] : all.sublist(start),
      hasNext: all.length >= want,
    );
  }

  PlaylistHit? _playlistHit(Map<String, dynamic> j) {
    final url = parseText(j['url']) ?? parseText(j['webpage_url']);
    final id = parseText(j['id']) ?? _listId(url);
    if (id == null || url == null || !url.contains('list=')) return null;
    return PlaylistHit(
      id: id,
      title: j['title'] as String? ?? '',
      url: url,
      channel: parseText(j['uploader'] ?? j['channel']) ?? '',
      thumbnailUrl: _thumbnailOf(j),
      trackCount: parseCount(j['playlist_count'] ?? j['n_entries']),
    );
  }

  String? _listId(String? url) =>
      url == null ? null : Uri.tryParse(url)?.queryParameters['list'];

  @override
  Future<MediaInfo> fetchInfo(String url) async {
    final out = await _exec([
      '--flat-playlist',
      '--dump-single-json',
      '--no-warnings',
      // 곡 정보에는 필요 없는 DASH · HLS 목록과 번역 자막을 받지 않아 더 빠르다.
      // (실측: 곡 하나 약 2.4~3.5초 → 1.9초, 쓰는 필드는 그대로)
      '--extractor-args',
      'youtube:skip=dash,hls,translated_subs',
      url,
    ]);
    final j = _decode(out);
    if (j == null) {
      throw const EngineException(EngineFailure.failed, 'bad response');
    }
    if (j['_type'] == 'playlist') {
      return PlaylistInfo(
        title: j['title'] as String? ?? '',
        entries: (j['entries'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_hit)
            .toList(),
        thumbnailUrl: _thumbnailOf(j),
      );
    }
    return VideoInfo(_hit(j));
  }

  @override
  Future<ChannelInfo> fetchChannel(String url) async {
    // 채널 탭의 영상은 받지 않고(`--playlist-items 0`) 채널 자체 정보만 읽는다.
    final out = await _exec([
      '--flat-playlist',
      '--playlist-items',
      '0',
      '--dump-single-json',
      '--no-warnings',
      url,
    ]);
    final j = _decode(out);
    if (j == null) {
      throw const EngineException(EngineFailure.failed, 'bad response');
    }
    return ChannelInfo(
      thumbnailUrl: avatarUrl(j['thumbnails']),
      subscriberCount: parseCount(j['channel_follower_count']),
    );
  }

  @override
  Future<AudioStream> resolveAudioStream(
    String url, {
    bool refresh = false,
    String? audioLanguage,
  }) async {
    // 오디오만 있는 형식 하나를 골라(macOS도 풀 수 있는 m4a 먼저) 주소만 읽는다.
    Future<AudioStream> read(List<String> extra) async {
      final out = await _exec([
        '-f',
        ytDlpAudioSelector(null, audioLanguage),
        '--no-playlist',
        '--dump-single-json',
        '--no-warnings',
        ...extra,
        url,
      ]);
      final j = _decode(out);
      final streamUrl = parseText(j?['url']);
      if (j == null || streamUrl == null) {
        throw const EngineException(EngineFailure.failed, 'bad response');
      }
      final headers = j['http_headers'];
      return AudioStream(
        url: streamUrl,
        headers: headers is Map
            ? {
                for (final e in headers.entries)
                  if (e.key is String && e.value is String)
                    e.key as String: e.value as String,
              }
            : const {},
      );
    }

    try {
      return await read(const []);
    } on EngineException catch (first) {
      if (first.failure != EngineFailure.failed) rethrow;
      // 기본 클라이언트로는 오디오 형식을 못 읽는 경우가 있다 (JS 실행기가 없는 환경 등).
      // 그런 환경에서도 주소를 주는 클라이언트로 한 번 더 시도하고, 그래도 안 되면 첫 오류를 알린다.
      try {
        return await read(const [
          '--extractor-args',
          'youtube:player_client=android_vr',
        ]);
      } on EngineException {
        throw first;
      }
    }
  }

  /// 형식 목록의 `language` · `format_note`에서 오디오 트랙을 읽는다. 하나뿐이면 빈 목록.
  @override
  Future<List<AudioLanguage>> fetchAudioLanguages(String url) async {
    final out = await _exec([
      '--dump-single-json',
      '--no-playlist',
      '--no-warnings',
      '--skip-download',
      url,
    ]);
    final j = _decode(out);
    final formats = j?['formats'];
    if (formats is! List) return const [];
    final byId = <String, AudioLanguage>{};
    for (final f in formats) {
      if (f is! Map || f['vcodec'] != 'none') continue;
      final id = parseText(f['language']);
      if (id == null || byId.containsKey(id)) continue;
      final note = parseText(f['format_note']) ?? '';
      byId[id] = AudioLanguage(
        id: id,
        name: _languageName(note) ?? id,
        isDefault: note.contains('default') || note.contains('original'),
      );
    }
    return byId.length < 2 ? const [] : byId.values.toList();
  }

  /// `English (US) original (default), medium` → `English (US)`.
  static String? _languageName(String note) {
    final head = note
        .split(',')
        .first
        .replaceAll(RegExp(r'\((default)\)|original|descriptive'), '')
        .trim();
    return head.isEmpty ? null : head;
  }

  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) async {
    // 어떤 자막이 있는지 먼저 읽고, 고른 언어 한 벌만 받는다 (모든 언어를 받지 않으려고).
    final out = await _exec([
      '--dump-single-json',
      '--no-playlist',
      '--no-warnings',
      '--skip-download',
      url,
    ]);
    final j = _decode(out);
    if (j == null) {
      throw const EngineException(EngineFailure.failed, 'bad response');
    }
    final pick = pickSubtitleLanguage(
      manual: _keys(j['subtitles']),
      automatic: _originalAutoKeys(j['automatic_captions']),
      prefer: preferLanguages,
    );
    if (pick == null) return null;

    final dir = await _makeTempDir();
    try {
      await _exec([
        '--skip-download',
        '--no-playlist',
        '--no-warnings',
        pick.automatic ? '--write-auto-subs' : '--write-subs',
        '--sub-langs',
        pick.language,
        '--sub-format',
        'vtt',
        '-o',
        '${dir.path}${Platform.pathSeparator}sub',
        url,
      ]);
      File? file;
      await for (final e in dir.list()) {
        if (e is File && e.path.endsWith('.vtt')) file = e;
      }
      if (file == null) return null;
      final cues = parseVtt(await file.readAsString());
      if (cues.isEmpty) return null;
      return SubtitleTrack(
        language: pick.language,
        automatic: pick.automatic,
        cues: cues,
      );
    } finally {
      try {
        await dir.delete(recursive: true);
      } on Object {
        // 임시 폴더라 못 지워도 괜찮다.
      }
    }
  }

  /// yt-dlp `subtitles` · `automatic_captions`의 언어 코드들 (라이브 채팅 제외).
  static List<String> _keys(Object? raw) => raw is Map
      ? [
          for (final k in raw.keys)
            if (k is String && k != 'live_chat') k,
        ]
      : const [];

  /// `automatic_captions`에서 영상 원어 자동 자막만 (유튜브가 번역해 둔 수십 개 언어는 뺀다).
  /// 번역본은 주소에 `tlang=`가 붙고, 원어는 `xx-orig` 키로 따로 온다. `-orig`가 있으면 그것만 쓴다.
  static List<String> _originalAutoKeys(Object? raw) {
    if (raw is! Map) return const [];
    final keys = <String>[];
    for (final e in raw.entries) {
      final k = e.key;
      if (k is! String || k == 'live_chat') continue;
      final formats = e.value;
      final translated =
          formats is List &&
          formats.isNotEmpty &&
          formats.every((f) => f is Map && '${f['url']}'.contains('tlang='));
      if (!translated) keys.add(k);
    }
    final orig = [
      for (final k in keys)
        if (k.endsWith('-orig')) k,
    ];
    return orig.isEmpty ? keys : orig;
  }

  Future<String> _exec(List<String> args) async {
    final ({int exitCode, String stdout, String stderr}) r;
    try {
      r = await _run(await _resolve(), args);
    } on ProcessException {
      throw const EngineException(EngineFailure.unavailable, 'yt-dlp');
    } on TimeoutException {
      throw const EngineException(EngineFailure.timeout, 'timeout');
    }
    if (r.exitCode != 0) {
      final err = r.stderr.trim();
      final failure = err.contains('Unsupported URL')
          ? EngineFailure.notFound
          : err.contains('Unable to download') || err.contains('getaddrinfo')
          ? EngineFailure.network
          : EngineFailure.failed;
      throw EngineException(failure, err);
    }
    return r.stdout;
  }

  Map<String, dynamic>? _decode(String s) {
    try {
      final j = jsonDecode(s);
      return j is Map<String, dynamic> ? j : null;
    } on FormatException {
      return null;
    }
  }

  /// `thumbnail`, 없으면 `thumbnails`의 마지막(가장 큰) 이미지 주소.
  String? _thumbnailOf(Map<String, dynamic> j) {
    final thumbs = j['thumbnails'];
    var thumb = j['thumbnail'] as String?;
    if (thumb == null && thumbs is List && thumbs.isNotEmpty) {
      // SoundCloud는 원본 크기가 맨 뒤라 목록에 쓰기엔 크다. 폭을 아는 것 중 500 이하에서 가장 큰 것을 쓴다.
      Map? pick;
      for (final t in thumbs) {
        if (t is! Map) continue;
        final w = t['width'];
        if (w is num && w <= 500) pick = t;
      }
      final last = thumbs.last;
      final chosen = pick ?? (last is Map ? last : null);
      thumb = chosen?['url'] as String?;
    }
    return thumb;
  }

  MediaHit _hit(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    final seconds = j['duration'];
    final thumb = _thumbnailOf(j);
    return MediaHit(
      id: id,
      title: j['title'] as String? ?? '',
      url:
          (j['webpage_url'] as String?) ??
          (j['url'] as String?) ??
          'https://www.youtube.com/watch?v=$id',
      uploader: (j['uploader'] ?? j['channel'] ?? '') as String,
      duration: seconds is num ? Duration(seconds: seconds.round()) : null,
      thumbnailUrl: thumb,
      categories: parseCategories(j['categories']),
      channelUrl: parseText(j['channel_url'] ?? j['uploader_url']),
      viewCount: parseCount(j['view_count']),
      uploadedAt: parseDate(j['upload_date']),
      description: parseText(j['description']) ?? '',
      likeCount: parseCount(j['like_count']),
      subscriberCount: parseCount(j['channel_follower_count']),
      creators: parseStrings(j['creators']),
      subtitleLangs: {
        ..._keys(j['subtitles']),
        ..._originalAutoKeys(j['automatic_captions']),
      }.toList(),
      autoSubtitleLangs: [
        for (final k in _originalAutoKeys(j['automatic_captions']))
          if (!_keys(j['subtitles']).contains(k)) k,
      ],
      album: parseText(j['album']) ?? '',
    );
  }
}

/// 받을 자막 언어를 고른다. 사람이 단 자막이 우선이고, [prefer] 순서(`ko` → `ko-KR` 같은 하위 코드 포함),
/// 없으면 첫 언어. 자동 자막은 원어(`-orig`)를 우선 쓴다. 쓸 자막이 없으면 null.
({String language, bool automatic})? pickSubtitleLanguage({
  required List<String> manual,
  required List<String> automatic,
  required List<String> prefer,
}) {
  String? choose(List<String> keys) {
    if (keys.isEmpty) return null;
    for (final p in prefer) {
      for (final k in keys) {
        if (k == p || k.startsWith('$p-')) return k;
      }
    }
    return keys.first;
  }

  final m = choose(manual);
  if (m != null) return (language: m, automatic: false);
  final orig = [
    for (final k in automatic)
      if (k.endsWith('-orig')) k,
  ];
  final a = choose(orig.isEmpty ? automatic : orig);
  return a == null ? null : (language: a, automatic: true);
}
