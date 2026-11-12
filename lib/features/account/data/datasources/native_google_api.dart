import 'package:flutter/services.dart';

import '../../domain/entities/google_account.dart';

/// 구글 YouTube Data API 읽기는 Android 네이티브(`GoogleApi`)가 한다: 쪽 넘기기 · 오류 가르기 · 항목 모양 만들기까지.
/// Dart는 로그인으로 얻은 토큰을 넘기고 결과만 받는다. 진행(지금까지 읽은 수)은 네이티브가 `progress`로 알려 준다.
class NativeGoogleApi {
  NativeGoogleApi({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/google_api');

  final MethodChannel _channel;
  final _progress = <int, void Function(int)>{};
  var _nextId = 0;
  var _listening = false;

  Future<void> _onCall(MethodCall call) async {
    if (call.method != 'progress') return;
    final args = call.arguments as Map<Object?, Object?>;
    _progress[args['id'] as int]?.call(args['loaded'] as int);
  }

  /// [kind]: `playlists` · `subscriptions`. 실패는 [AccountException].
  Future<List<Map<Object?, Object?>>> list({
    required String token,
    required String kind,
    required Map<String, String> query,
    required int maxPages,
    void Function(int loaded)? onProgress,
  }) async {
    if (!_listening) {
      _channel.setMethodCallHandler(_onCall);
      _listening = true;
    }
    final id = _nextId++;
    if (onProgress != null) _progress[id] = onProgress;
    try {
      final items = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'list',
        {
          'token': token,
          'kind': kind,
          'query': query,
          'maxPages': maxPages,
          'progressId': onProgress == null ? null : id,
        },
      );
      return items ?? const [];
    } on PlatformException catch (e) {
      throw AccountException(_failureOf(e.code), e.message ?? '');
    } finally {
      _progress.remove(id);
    }
  }

  static AccountFailure _failureOf(String code) => switch (code) {
    'unauthorized' => AccountFailure.unauthorized,
    'no_channel' => AccountFailure.noChannel,
    'network' => AccountFailure.network,
    'timeout' => AccountFailure.timeout,
    _ => AccountFailure.failed,
  };
}
