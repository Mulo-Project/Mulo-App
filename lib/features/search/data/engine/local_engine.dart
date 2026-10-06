import 'dart:convert';
import 'dart:io';

import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_source.dart';
import '../../domain/repositories/downloader_engine.dart';
import 'audio_format_policy.dart';
import 'json_fields.dart';

/// 프로세스 실행 하나 (테스트에서 바꿔 끼운다).
typedef RunProcess =
    Future<({int exitCode, String stdout, String stderr})> Function(
      String executable,
      List<String> args,
    );

Future<({int exitCode, String stdout, String stderr})> _defaultRun(
  String executable,
  List<String> args,
) async {
  final r = await Process.run(
    executable,
    args,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  return (
    exitCode: r.exitCode,
    stdout: r.stdout as String,
    stderr: r.stderr as String,
  );
}

/// 로컬 모드: 이 기기에서 yt-dlp를 직접 실행해 찾는다 (데스크톱).
/// Android 로컬(full 빌드)은 아직 없다.
class LocalEngine implements DownloaderEngine {
  LocalEngine({Future<String> Function()? resolveExecutable, RunProcess? run})
    : _resolve = resolveExecutable ?? (() async => 'yt-dlp'),
      _run = run ?? _defaultRun;

  /// 실행할 yt-dlp 경로 (앱이 받은 것 또는 PATH의 `yt-dlp`).
  final Future<String> Function() _resolve;
  final RunProcess _run;

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
    // 최신순은 yt-dlp의 날짜 순 검색(ytsearchdate · scsearchdate)으로 찾는다.
    final base = source == SearchSource.web ? 'scsearch' : 'ytsearch';
    final prefix = newest ? '${base}date' : base;
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
  Future<AudioStream> resolveAudioStream(String url) async {
    // 오디오만 있는 형식 하나를 골라(macOS도 풀 수 있는 m4a 먼저) 주소만 읽는다.
    Future<AudioStream> read(List<String> extra) async {
      final out = await _exec([
        '-f',
        ytDlpAudioSelector(),
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

  Future<String> _exec(List<String> args) async {
    final ({int exitCode, String stdout, String stderr}) r;
    try {
      r = await _run(await _resolve(), args);
    } on ProcessException {
      throw const EngineException(EngineFailure.unavailable, 'yt-dlp');
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

  MediaHit _hit(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    final seconds = j['duration'];
    final thumbs = j['thumbnails'];
    var thumb = j['thumbnail'] as String?;
    if (thumb == null && thumbs is List && thumbs.isNotEmpty) {
      final last = thumbs.last;
      if (last is Map) thumb = last['url'] as String?;
    }
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
    );
  }
}
