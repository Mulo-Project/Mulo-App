import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/audio_file_downloader.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/audio_transcoder.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/download_queue_store.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_options.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_source.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_stream.dart';

/// 구간 요청(Range)을 받는 작은 서버 (이어받기 시험용).
class _RangeServer {
  _RangeServer(this.body, {this.honorRange = true});

  final List<int> body;
  final bool honorRange;
  final ranges = <String?>[];
  late final HttpServer _server;

  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final range = req.headers.value('range');
      ranges.add(range);
      final m = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(range ?? '');
      final res = req.response;
      res.headers.contentType = ContentType('audio', 'webm');
      if (!honorRange || m == null) {
        res.statusCode = 200;
        res.contentLength = body.length;
        res.add(body);
      } else {
        final from = int.parse(m.group(1)!);
        if (from >= body.length) {
          res.statusCode = 416;
        } else {
          final to = int.parse(m.group(2)!).clamp(0, body.length - 1);
          res.statusCode = 206;
          res.headers.set('content-range', 'bytes $from-$to/${body.length}');
          res.add(body.sublist(from, to + 1));
        }
      }
      await res.close();
    });
    return 'http://127.0.0.1:${_server.port}/a.webm?mime=audio%2Fwebm';
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('mulo_rs'));
  tearDown(() => tmp.delete(recursive: true));

  final body = List<int>.generate(25, (i) => i);

  Future<List<int>> run(
    _RangeServer server,
    File target, {
    String? resumeMime,
    String? mimeFromCallback,
  }) async {
    final url = await server.start();
    addTearDown(server.stop);
    final progress = <double>[];
    final audio = await HttpAudioFileDownloader(chunkSize: 10).download(
      AudioStream(url: url),
      target,
      token: DownloadCancelToken(),
      onProgress: progress.add,
      resumeMime: resumeMime,
      onMime: (_) {},
    );
    expect(progress.last, 1);
    expect(audio.mime, 'audio/webm');
    return target.readAsBytes();
  }

  test('받다 만 파일이 있으면 그 뒤부터 구간을 요청해 이어 받는다', () async {
    final target = File('${tmp.path}/p.part')
      ..writeAsBytesSync(body.sublist(0, 12));
    final server = _RangeServer(body);
    final bytes = await run(server, target, resumeMime: 'audio/webm');
    expect(bytes, body);
    expect(server.ranges.first, 'bytes=12-21');
    expect(server.ranges, hasLength(2));
  });

  test('이어받을 형식 표시가 없으면 처음부터 다시 받는다', () async {
    final target = File('${tmp.path}/p.part')
      ..writeAsBytesSync(body.sublist(0, 12));
    final server = _RangeServer(body);
    final bytes = await run(server, target);
    expect(bytes, body);
    expect(server.ranges.first, 'bytes=0-9');
  });

  test('다른 형식의 주소면 처음부터 다시 받는다', () async {
    final target = File('${tmp.path}/p.part')
      ..writeAsBytesSync(body.sublist(0, 12));
    final server = _RangeServer(body);
    final bytes = await run(server, target, resumeMime: 'audio/mp4');
    expect(bytes, body);
    expect(server.ranges.first, 'bytes=0-9');
  });

  test('이미 다 받아 둔 파일은 범위 밖 응답(416)을 끝난 것으로 본다', () async {
    final target = File('${tmp.path}/p.part')..writeAsBytesSync(body);
    final server = _RangeServer(body);
    final bytes = await run(server, target, resumeMime: 'audio/webm');
    expect(bytes, body);
  });

  test('서버가 구간을 무시하고 전부 보내면 앞의 것을 버리고 다시 쓴다', () async {
    final target = File('${tmp.path}/p.part')
      ..writeAsBytesSync(body.sublist(0, 12));
    final server = _RangeServer(body, honorRange: false);
    final bytes = await run(server, target, resumeMime: 'audio/webm');
    expect(bytes, body);
  });

  test('주소 키: 같은 영상의 여러 주소 모양을 하나로 본다', () {
    const id = 'youtube:abc123';
    expect(downloadSourceKey('https://youtu.be/abc123?t=5'), id);
    expect(
      downloadSourceKey('https://www.youtube.com/watch?v=abc123&list=PL'),
      id,
    );
    expect(downloadSourceKey('https://m.youtube.com/shorts/abc123'), id);
    expect(downloadSourceKey('https://youtube.com/embed/abc123'), id);
    expect(
      downloadSourceKey('  https://example.com/a.mp3 '),
      'https://example.com/a.mp3',
    );
    expect(downloadSourceKey('not a url'), 'not a url');
  });

  test('변환 방법: mp3만 192kbps로 바꾸고 opus · m4a는 원본 그대로', () {
    expect(TranscodePlan.of(AudioFormat.mp3)?.bitrateKbps, 192);
    expect(TranscodePlan.of(AudioFormat.opus), isNull);
    expect(TranscodePlan.of(AudioFormat.m4a), isNull);
  });

  test('저장한 대기열 항목은 JSON을 거쳐도 그대로다', () {
    const request = DownloadRequest(
      title: '곡',
      artist: '가수',
      genre: '팝',
      playlistIds: {'a', 'b'},
      format: AudioFormat.mp3,
      savePath: '/music/x',
      duration: Duration(seconds: 200),
      color: 0xFF112233,
      thumbnailUrl: 'https://i.test/t.jpg',
      cover: CoverArt.web(
        'https://i.test/c.jpg',
        transform: CoverTransform(scale: 2, dx: .1, dy: -.2),
      ),
      url: 'https://youtu.be/abc',
    );
    expect(decodeDownloadRequest(encodeDownloadRequest(request)), request);
    // 예전에 저장된 대기열의 quality 값은 무시하고 읽는다.
    expect(
      decodeDownloadRequest({
        ...encodeDownloadRequest(request),
        'quality': 'saver',
      }),
      request,
    );
    expect(
      decodeDownloadRequest(
        encodeDownloadRequest(
          const DownloadRequest(title: 't', cover: CoverArt.file('/a/b.jpg')),
        ),
      ).cover,
      const CoverArt.file('/a/b.jpg'),
    );
    expect(
      DownloadStatus.values.byName(DownloadStatus.paused.name),
      DownloadStatus.paused,
    );
  });
}
