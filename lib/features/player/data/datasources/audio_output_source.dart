import 'dart:async';

import 'package:flutter/services.dart';

/// Android 네이티브(`music_app/audio_output`)에 지금 출력 기기를 묻는다.
/// 다른 플랫폼이나 실패는 null(모름)로 본다.
class AudioOutputSource {
  AudioOutputSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/audio_output');

  final MethodChannel _channel;
  StreamController<void>? _changes;

  /// `{type: speaker|wired|bluetooth|usb|other, name: String}`
  Future<Map<String, String>?> current() async {
    try {
      final map = await _channel.invokeMapMethod<String, String>('current');
      return map;
    } on Exception {
      return null;
    }
  }

  /// 출력 기기가 연결되거나 끊길 때마다 알려 준다 (네이티브가 `changed`를 보낸다).
  Stream<void> get changes {
    return (_changes ??= StreamController<void>.broadcast(
      onListen: () => _channel.setMethodCallHandler((call) async {
        if (call.method == 'changed') _changes?.add(null);
      }),
    )).stream;
  }
}
