import 'package:flutter/services.dart';

import '../../search/domain/entities/engine_exception.dart';

/// 로컬 엔진(yt-dlp) 호출: Android 네이티브(`music_app/ytdlp_engine`, `YtDlpEngine`)가 검색 · 곡 정보 ·
/// 재생 주소 · 자막 · 영상 저장을 하고, Dart는 값을 보내 결과 맵만 받는다 (실행 줄 · 시간 제한 · 오류 가르기도 네이티브).
/// 실패는 [EngineException]으로 바뀐다. 이 빌드에 엔진이 없으면(lite · Android 밖) `unavailable`이다.
class NativeYtDlp {
  NativeYtDlp({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/ytdlp_engine') {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  final MethodChannel _channel;

  /// 진행률을 받겠다고 한 실행(id)의 받는 쪽.
  final _progress = <String, void Function(double)>{};
  int _seq = 0;

  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method != 'progress') return;
    final args = call.arguments;
    if (args is! Map) return;
    final p = (args['progress'] as num?)?.toDouble();
    if (p != null) _progress[args['id']]?.call(p);
  }

  /// 이 빌드에 로컬 엔진이 들어 있는지 (full · Android). Android 밖에는 채널이 없어 false다.
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<Map<Object?, Object?>> search(
    String prefix,
    String query,
    int page,
    int size,
  ) => _map('search', {
    'prefix': prefix,
    'query': query,
    'page': page,
    'size': size,
  });

  Future<Map<Object?, Object?>> searchPlaylists(
    String query,
    int page,
    int size,
  ) => _map('searchPlaylists', {'query': query, 'page': page, 'size': size});

  Future<Map<Object?, Object?>> info(String url) => _map('info', {'url': url});

  Future<Map<Object?, Object?>> channel(String url) =>
      _map('channel', {'url': url});

  Future<Map<Object?, Object?>> audio(String url, String? language) =>
      _map('audio', {'url': url, 'language': language});

  Future<Map<Object?, Object?>> video(String url, int maxHeight) =>
      _map('video', {'url': url, 'maxHeight': maxHeight});

  Future<List<Map<Object?, Object?>>> audioLanguages(String url) async =>
      (await _call(
            () => _channel.invokeListMethod<Map<Object?, Object?>>(
              'audioLanguages',
              {'url': url},
            ),
          )) ??
          const [];

  /// 고른 언어 한 벌의 자막 (`language` · `automatic` · `cues`). 쓸 자막이 없으면 null.
  Future<Map<Object?, Object?>?> subtitles(
    String url,
    List<String> prefer,
  ) => _call(
    () => _channel.invokeMapMethod<Object?, Object?>('subtitles', {
      'url': url,
      'prefer': prefer,
    }),
  );

  /// 영상(+소리)을 받아 `<dir>/<stem>.<extension>`으로 합쳐 둔다. 못 받으면 [EngineException].
  /// 몇 분 걸릴 수 있어 [onProgress](0 ~ 1)로 진행을 알린다.
  Future<void> saveVideo({
    required String url,
    required int maxHeight,
    required String extension,
    required String dir,
    required String stem,
    void Function(double progress)? onProgress,
  }) async {
    final id = 'save${_seq++}';
    if (onProgress != null) _progress[id] = onProgress;
    try {
      await _call(
        () => _channel.invokeMethod<void>('saveVideo', {
          'url': url,
          'maxHeight': maxHeight,
          'extension': extension,
          'dir': dir,
          'stem': stem,
          'id': onProgress == null ? null : id,
        }),
      );
    } finally {
      _progress.remove(id);
    }
  }

  Future<Map<Object?, Object?>> _map(
    String method,
    Map<String, Object?> args,
  ) async {
    final r = await _call(
      () => _channel.invokeMapMethod<Object?, Object?>(method, args),
    );
    if (r == null) throw const EngineException(EngineFailure.failed, 'empty');
    return r;
  }

  Future<T?> _call<T>(Future<T?> Function() call) async {
    try {
      return await call();
    } on MissingPluginException {
      throw const EngineException(EngineFailure.unavailable, 'yt-dlp');
    } on PlatformException catch (e) {
      throw EngineException(_failure(e.code), e.message ?? e.code);
    }
  }

  static EngineFailure _failure(String code) => switch (code) {
    'unavailable' => EngineFailure.unavailable,
    'network' => EngineFailure.network,
    'timeout' => EngineFailure.timeout,
    'not_found' => EngineFailure.notFound,
    _ => EngineFailure.failed,
  };
}
