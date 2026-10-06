import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../../search/domain/entities/audio_stream.dart';

/// 받기를 멈출 때 쓰는 표시. [cancel]하면 받던 곡이 곧 [DownloadAborted]로 멈춘다.
class DownloadCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// 받던 중 사용자가 멈췄다 (취소 · 일시정지).
class DownloadAborted implements Exception {
  const DownloadAborted();
}

/// 받지 못했다 (주소가 거절하거나 네트워크가 끊김). [message]는 안내에 덧붙인다.
class DownloadFailed implements Exception {
  const DownloadFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 받아 둔 오디오 파일 (임시 위치).
class DownloadedAudio {
  const DownloadedAudio(this.file, this.extension, this.mime);

  final File file;

  /// 점 없이: `weba`, `m4a` 등.
  final String extension;
  final String mime;
}

/// 오디오 스트림 주소에서 파일을 받아 임시 파일에 쓴다.
abstract interface class AudioFileDownloader {
  /// [stream]을 [target]에 받는다. 열리지 않으면 [AudioStream.fallbacks]를 차례로 쓴다.
  /// [onProgress]는 0 ~ 1 (크기를 알 때만). 멈추면 [DownloadAborted], 못 받으면 [DownloadFailed].
  Future<DownloadedAudio> download(
    AudioStream stream,
    File target, {
    required DownloadCancelToken token,
    required void Function(double progress) onProgress,
  });
}

/// 구간 요청(Range)으로 조금씩 받는다.
///
/// YouTube 주소는 끝을 안 정한 구간 요청이나 한 번에 전부 받는 요청을 막는 일이 있어서
/// (미리 듣기 기록 참고) 항상 [chunkSize]씩 구간을 정해 요청한다.
class HttpAudioFileDownloader implements AudioFileDownloader {
  HttpAudioFileDownloader({
    this.chunkSize = 10 * 1024 * 1024,
    this.retriesPerChunk = 2,
  });

  final int chunkSize;
  final int retriesPerChunk;

  @override
  Future<DownloadedAudio> download(
    AudioStream stream,
    File target, {
    required DownloadCancelToken token,
    required void Function(double progress) onProgress,
  }) async {
    final errors = <String>[];
    for (final s in [stream, ...stream.fallbacks]) {
      if (token.isCancelled) throw const DownloadAborted();
      try {
        return await _downloadOne(s, target, token, onProgress);
      } on DownloadFailed catch (e) {
        errors.add(e.message);
      }
    }
    throw DownloadFailed(errors.join(' | '));
  }

  Future<DownloadedAudio> _downloadOne(
    AudioStream stream,
    File target,
    DownloadCancelToken token,
    void Function(double) onProgress,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    late IOSink sink;
    var sinkOpen = false;
    try {
      final url = Uri.parse(stream.url);
      sink = target.openWrite();
      sinkOpen = true;
      var offset = 0;
      int? total;
      String? mime = url.queryParameters['mime'];
      while (total == null || offset < total) {
        if (token.isCancelled) throw const DownloadAborted();
        final end = offset + chunkSize - 1;
        final chunk = await _requestChunk(
          client,
          url,
          stream.headers,
          offset,
          end,
          token,
        );
        mime ??= chunk.mime;
        total = chunk.total ?? (offset + chunk.bytes.length);
        if (chunk.wholeBody) {
          // 서버가 구간을 무시하고 전부 보냈다: 앞에서 받은 것을 버리고 처음부터 쓴다.
          offset = 0;
          await sink.close();
          sink = target.openWrite();
        }
        sink.add(chunk.bytes);
        offset += chunk.bytes.length;
        if (chunk.bytes.isEmpty) {
          throw const DownloadFailed('빈 응답');
        }
        onProgress(total == 0 ? 0 : (offset / total).clamp(0, 1).toDouble());
      }
      await sink.flush();
      await sink.close();
      sinkOpen = false;
      final m = _normalizeMime(mime);
      return DownloadedAudio(target, _extensionFor(m), m);
    } on DownloadAborted {
      rethrow;
    } on DownloadFailed {
      rethrow;
    } on Object catch (e) {
      throw DownloadFailed('$e');
    } finally {
      try {
        if (sinkOpen) await sink.close();
      } on Object {
        // 이미 닫혔거나 쓰기가 실패한 뒤다.
      }
      client.close(force: true);
    }
  }

  Future<_Chunk> _requestChunk(
    HttpClient client,
    Uri url,
    Map<String, String> headers,
    int from,
    int to,
    DownloadCancelToken token,
  ) async {
    Object? last;
    for (var attempt = 0; attempt <= retriesPerChunk; attempt++) {
      if (token.isCancelled) throw const DownloadAborted();
      try {
        final req = await client.getUrl(url);
        headers.forEach(req.headers.set);
        req.headers.set('range', 'bytes=$from-$to');
        final resp = await req.close().timeout(const Duration(seconds: 20));
        final status = resp.statusCode;
        if (status != 206 && status != 200) {
          await resp.drain<void>();
          // 403 등은 다시 해도 같다. 다음 형식 주소로 넘어간다.
          if (status == 403 || status == 404 || status == 410) {
            throw DownloadFailed('HTTP $status (구간 $from)');
          }
          throw HttpException('HTTP $status');
        }
        final bytes = BytesBuilder(copy: false);
        await for (final data in resp.timeout(const Duration(seconds: 20))) {
          if (token.isCancelled) throw const DownloadAborted();
          bytes.add(data);
        }
        final range = resp.headers.value('content-range');
        final totalFromRange = range == null
            ? null
            : int.tryParse(range.split('/').last);
        return _Chunk(
          bytes.takeBytes(),
          status == 206
              ? totalFromRange
              : resp.contentLength > 0
              ? resp.contentLength
              : null,
          status == 200,
          resp.headers.contentType?.mimeType,
        );
      } on DownloadAborted {
        rethrow;
      } on DownloadFailed {
        rethrow;
      } on Object catch (e) {
        last = e;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw DownloadFailed('$last');
  }

  static String _normalizeMime(String? mime) {
    final m = mime?.split(';').first.trim().toLowerCase();
    if (m == null || !m.startsWith('audio/')) return 'audio/webm';
    return m;
  }

  static String _extensionFor(String mime) => switch (mime) {
    'audio/mp4' || 'audio/x-m4a' || 'audio/m4a' => 'm4a',
    'audio/mpeg' => 'mp3',
    'audio/ogg' || 'audio/opus' => 'opus',
    _ => 'weba',
  };
}

class _Chunk {
  const _Chunk(this.bytes, this.total, this.wholeBody, this.mime);

  final List<int> bytes;
  final int? total;

  /// 구간 요청이 무시되어 전체가 왔다 (HTTP 200).
  final bool wholeBody;
  final String? mime;
}
