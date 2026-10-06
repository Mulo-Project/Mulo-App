// ignore_for_file: experimental_member_use
import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/preview_progress.dart';
import '../../domain/repositories/preview_player.dart';

/// 미리 듣기용 just_audio 플레이어. 메인 재생의 플레이어와는 별개라 대기열 · 미니 플레이어에
/// 끼어들지 않는다. 플레이어는 처음 쓸 때 만든다.
class JustAudioPreviewPlayer implements PreviewPlayer {
  AudioPlayer? _player;
  final _completed = StreamController<void>.broadcast();
  final _progress = StreamController<PreviewProgress>.broadcast();
  final _failures = StreamController<String>.broadcast();
  StreamSubscription<ProcessingState>? _processing;
  StreamSubscription<PlaybackEvent>? _events;

  /// 지금 재생 중인 스트림과, 앱의 HTTP로 받아 넘기는 방식으로 바꿨는지.
  AudioStream? _stream;
  var _viaApp = false;
  StreamSubscription<Duration>? _position;

  AudioPlayer _ensure() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _processing = player.processingStateStream
        .where((s) => s == ProcessingState.completed)
        .listen((_) => _completed.add(null));
    _position = player.positionStream.listen(
      (p) => _progress.add(
        PreviewProgress(position: p, duration: player.duration),
      ),
    );
    // 재생이 시작된 뒤의 오류(주소가 중간에 막힘 등)는 여기로 온다.
    _events = player.playbackEventStream.listen((_) {}, onError: _onError);
    return _player = player;
  }

  @override
  Future<void> play(AudioStream stream) async {
    final player = _ensure();
    _stream = stream;
    _viaApp = false;
    try {
      try {
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(stream.url),
            headers: stream.headers.isEmpty ? null : stream.headers,
          ),
        );
      } on PlayerException catch (direct) {
        // 플레이어(ExoPlayer 등)가 직접 못 열면(Source error) 앱이 받아서 넘겨 준다.
        // 앱의 HTTP로는 열리는 주소가 있다 (주소 확인에 쓴 것과 같은 방식).
        try {
          _viaApp = true;
          await player.setAudioSource(
            _HttpRangeSource(Uri.parse(stream.url), stream.headers),
          );
        } on PlayerException catch (viaApp) {
          throw EngineException(
            EngineFailure.failed,
            'direct: ${direct.message} | app: ${viaApp.message}',
          );
        }
      }
    } on PlayerInterruptedException {
      // 불러오는 중에 멈춤 · 다른 곡으로 바뀜: 호출한 쪽이 이미 알고 있다.
      return;
    } on PlayerException catch (e) {
      throw EngineException(EngineFailure.failed, e.message ?? '');
    } on FormatException catch (e) {
      throw EngineException(EngineFailure.failed, e.message);
    } on EngineException {
      rethrow;
    } catch (e) {
      // 그 밖의 오류도 "불러오는 중"에 멈춰 있지 않게 실패로 돌려준다.
      throw EngineException(EngineFailure.failed, '$e');
    }
    // 재생은 곡 끝까지 끝나지 않는 Future라 기다리지 않는다.
    unawaited(player.play().catchError((Object _) {}));
  }

  Future<void> _onError(Object error, StackTrace _) async {
    final stream = _stream;
    final player = _player;
    if (stream == null || player == null) return;
    final reason = error is PlayerException ? error.message : '$error';
    if (!_viaApp) {
      // 직접 열었는데 재생 중에 막혔다: 앱의 HTTP로 받아 넘기는 방식으로 이어서 틀어 본다.
      _viaApp = true;
      try {
        await player.setAudioSource(
          _HttpRangeSource(Uri.parse(stream.url), stream.headers),
          initialPosition: player.position,
        );
        unawaited(player.play().catchError((Object _) {}));
        return;
      } on Object catch (e) {
        _failures.add('direct: $reason | app: $e');
        return;
      }
    }
    _failures.add('app: $reason');
  }

  @override
  Future<void> stop() async {
    // 불러오는 중이어도 멈출 수 있다 (진행 중이던 setAudioSource가 중단된다).
    _stream = null;
    await _player?.stop();
  }

  @override
  Stream<void> watchCompleted() => _completed.stream;

  @override
  Stream<String> watchFailures() => _failures.stream;

  @override
  Stream<PreviewProgress> watchProgress() => _progress.stream;

  Future<void> dispose() async {
    await _processing?.cancel();
    await _position?.cancel();
    await _events?.cancel();
    await _failures.close();
    await _progress.close();
    await _player?.dispose();
    _player = null;
    await _completed.close();
  }
}

/// 주소를 앱의 HTTP(`dart:io`)로 받아 플레이어에 넘기는 소스. 구간 요청(Range)을 그대로 전달한다.
class _HttpRangeSource extends StreamAudioSource {
  _HttpRangeSource(this._url, this._headers);

  final Uri _url;
  final Map<String, String> _headers;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final client = HttpClient()..idleTimeout = const Duration(seconds: 5);
    final req = await client.getUrl(_url);
    _headers.forEach(req.headers.set);
    req.headers.set(
      'range',
      'bytes=${start ?? 0}-${end == null ? '' : end - 1}',
    );
    final resp = await req.close();
    if (resp.statusCode >= 400) {
      client.close(force: true);
      throw HttpException('HTTP ${resp.statusCode}', uri: _url);
    }
    // 총 길이: `Content-Range: bytes 0-1023/1300631`의 끝 숫자, 없으면 본문 길이.
    final range = resp.headers.value('content-range');
    final total = range == null
        ? null
        : int.tryParse(range.split('/').last.trim());
    final offset = start ?? 0;
    return StreamAudioResponse(
      sourceLength:
          total ?? (resp.contentLength < 0 ? null : resp.contentLength),
      contentLength: resp.contentLength < 0 ? null : resp.contentLength,
      offset: offset,
      stream: resp,
      contentType: resp.headers.contentType?.mimeType ?? 'audio/mp4',
    );
  }
}
