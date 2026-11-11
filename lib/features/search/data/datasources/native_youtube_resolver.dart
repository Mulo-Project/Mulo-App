import 'package:flutter/services.dart';

import '../../domain/entities/audio_language.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/video_stream.dart';
import '../engine/audio_format_policy.dart';

/// 유튜브 재생 주소를 Android 네이티브(`YoutubeResolveChannel`)가 읽는다 (D-062의 읽기를 Dart에서 옮겼다).
/// Dart는 videoId를 보내 결과만 받으므로, 앱이 백그라운드에 있어도 읽기가 끊기지 않는다.
/// 못 읽으면 null(쓸 형식 없음) 또는 [EngineException]이고, 호출한 쪽(`YoutubeResolveEngine`)이 yt-dlp로 넘어간다.
class NativeYoutubeResolver {
  NativeYoutubeResolver({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/youtube_resolve');

  final MethodChannel _channel;

  /// 소리 주소 (선호 형식 먼저, 나머지는 `fallbacks`).
  Future<AudioStream?> audio(String videoId, {String? language}) async {
    final r = await _call('audio', {
      'videoId': videoId,
      'language': language,
      'preferWebm': preferredAudioFormat() == AudioFormat.webm,
    });
    return r == null ? null : _audio(r);
  }

  /// 영상 주소 (소리가 든 형식이면 `muxed`).
  Future<VideoStream?> video(String videoId, int maxHeight) async {
    final r = await _call('video', {
      'videoId': videoId,
      'maxHeight': maxHeight,
    });
    if (r == null) return null;
    return VideoStream(
      url: r['url'] as String,
      headers: _headers(r['headers']),
      muxed: r['muxed'] as bool? ?? false,
    );
  }

  /// 오디오 언어 트랙 목록 (둘 이상일 때만 비어 있지 않다).
  Future<List<AudioLanguage>> languages(String videoId) async {
    try {
      final r = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'languages',
        {'videoId': videoId},
      );
      return [
        for (final m in r ?? const <Map<Object?, Object?>>[])
          AudioLanguage(
            id: m['id'] as String,
            name: m['name'] as String? ?? m['id'] as String,
            isDefault: m['isDefault'] as bool? ?? false,
          ),
      ];
    } on PlatformException catch (e) {
      throw EngineException(EngineFailure.failed, e.message ?? e.code);
    }
  }

  Future<Map<Object?, Object?>?> _call(
    String method,
    Map<String, Object?> args,
  ) async {
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(method, args);
    } on PlatformException catch (e) {
      throw EngineException(EngineFailure.failed, e.message ?? e.code);
    }
  }

  AudioStream _audio(Map<Object?, Object?> m) => AudioStream(
    url: m['url'] as String,
    headers: _headers(m['headers']),
    fallbacks: [
      for (final f in (m['fallbacks'] as List<Object?>? ?? const []))
        _audio(f! as Map<Object?, Object?>),
    ],
  );

  Map<String, String> _headers(Object? h) => {
    for (final e in (h as Map<Object?, Object?>? ?? const {}).entries)
      e.key! as String: e.value! as String,
  };
}
