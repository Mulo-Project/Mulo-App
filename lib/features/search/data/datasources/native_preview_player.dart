import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/preview_progress.dart';
import '../../domain/entities/preview_snapshot.dart';
import '../../domain/entities/stream_cache_info.dart';
import '../../domain/entities/video_stream.dart';
import '../../domain/repositories/preview_player.dart';

/// 미리 듣기 소리를 Android 네이티브(`PreviewChannel`, ExoPlayer)가 낸다 (D-093의 경계: 재생 엔진은 네이티브).
/// 메인 재생과는 따로라 대기열 · 미니 플레이어에 끼어들지 않는다. 알림은 [PreviewCubit]이 따로 띄운다.
class NativePreviewPlayer implements PreviewPlayer {
  NativePreviewPlayer({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/preview') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  final _completed = StreamController<void>.broadcast();
  final _progress = StreamController<PreviewProgress>.broadcast();
  final _failures = StreamController<String>.broadcast();
  final _saved = StreamController<({String id, bool ok})>.broadcast();
  final _savedProgress =
      StreamController<({String id, int percent})>.broadcast();

  Future<void> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'completed':
        _completed.add(null);
      case 'progress':
        final args = call.arguments as Map;
        final duration = args['duration'] as num?;
        _progress.add(
          PreviewProgress(
            position: Duration(milliseconds: (args['position'] as num).toInt()),
            buffered: Duration(
              milliseconds: ((args['buffered'] as num?) ?? 0).toInt(),
            ),
            duration: duration == null
                ? null
                : Duration(milliseconds: duration.toInt()),
          ),
        );
      case 'failure':
        _failures.add(call.arguments as String? ?? '');
      case 'savedProgress':
        final args = call.arguments as Map;
        _savedProgress.add((
          id: args['id'] as String,
          percent: (args['percent'] as num).toInt(),
        ));
      case 'saved':
        final args = call.arguments as Map;
        _saved.add((id: args['id'] as String, ok: args['ok'] as bool));
    }
  }

  @override
  Future<void> play(AudioStream stream) async {
    // 형식이 무엇이든 재생은 되게: 안 열리면 다른 형식 주소로 차례로 시도한다.
    EngineException? first;
    for (final candidate in [stream, ...stream.fallbacks]) {
      try {
        await _channel.invokeMethod<void>('play', {
          'url': candidate.url,
          'headers': candidate.headers,
        });
        return;
      } on PlatformException catch (e) {
        first ??= EngineException(EngineFailure.failed, e.message ?? e.code);
      }
    }
    throw first!;
  }

  @override
  Future<void> playVideo(VideoStream stream) => _channel.invokeMethod<void>(
    'playVideo',
    {'url': stream.url, 'headers': stream.headers},
  );

  @override
  Future<void> playMainVideo(VideoStream? stream) => stream == null
      ? _channel.invokeMethod<void>('stopVideo')
      : _channel.invokeMethod<void>('playVideo', {
          'url': stream.url,
          'headers': stream.headers,
          'followMain': true,
        });

  @override
  Future<StreamCacheInfo> cacheInfo() async {
    final m = await _channel.invokeMapMethod<String, dynamic>('cacheInfo');
    return StreamCacheInfo(
      usedBytes: (m?['usedBytes'] as num?)?.toInt() ?? 0,
      limitBytes: (m?['limitBytes'] as num?)?.toInt() ?? 0,
      savedBytes: (m?['savedBytes'] as num?)?.toInt() ?? 0,
      freeBytes: (m?['freeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<bool> enterPip() async =>
      await _channel.invokeMethod<bool>('enterPip') ?? false;

  @override
  Future<void> setCacheLimit(int bytes) =>
      _channel.invokeMethod<void>('setCacheLimit', bytes);

  @override
  Future<void> clearCache() => _channel.invokeMethod<void>('clearCache');

  @override
  Future<void> setSavedStreams(List<String> streamIds) =>
      _channel.invokeMethod<void>('setSaved', {'ids': streamIds});

  @override
  Future<String?> saveStream(String id, List<VideoStream> streams) =>
      _channel.invokeMethod<String>('saveStream', {
        'id': id,
        'streams': [
          for (final s in streams) {'url': s.url, 'headers': s.headers},
        ],
      });

  @override
  Future<void> removeSavedStream(String id, String? streamId) => _channel
      .invokeMethod<void>('removeSaved', {'id': id, 'streamId': streamId});

  @override
  Stream<({String id, bool ok})> watchSaved() => _saved.stream;

  @override
  Stream<({String id, int percent})> watchSavedProgress() =>
      _savedProgress.stream;

  @override
  Future<void> remember(MediaHit hit) =>
      _channel.invokeMethod<void>('remember', {
        'id': hit.id,
        'title': hit.title,
        'url': hit.url,
        'uploader': hit.uploader,
        'thumbnail': hit.thumbnailUrl,
      });

  @override
  Future<PreviewSnapshot?> current() async {
    final m = await _channel.invokeMapMethod<String, Object?>('current');
    if (m == null) return null;
    final duration = m['durationMs'] as num?;
    return PreviewSnapshot(
      hit: MediaHit(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        url: m['url'] as String? ?? '',
        uploader: m['uploader'] as String? ?? '',
        thumbnailUrl: m['thumbnail'] as String?,
      ),
      position: Duration(milliseconds: (m['positionMs'] as num).toInt()),
      duration: duration == null
          ? null
          : Duration(milliseconds: duration.toInt()),
      paused: m['paused'] as bool? ?? false,
    );
  }

  @override
  Future<void> seek(Duration position) =>
      _channel.invokeMethod<void>('seek', position.inMilliseconds);

  @override
  Future<void> pause() => _channel.invokeMethod<void>('pause');

  @override
  Future<void> resume() => _channel.invokeMethod<void>('resume');

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  Stream<void> watchCompleted() => _completed.stream;

  @override
  Stream<String> watchFailures() => _failures.stream;

  @override
  Stream<PreviewProgress> watchProgress() => _progress.stream;
}
