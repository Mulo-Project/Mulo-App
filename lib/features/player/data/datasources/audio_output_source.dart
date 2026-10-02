import 'package:flutter/services.dart';

/// Android 네이티브(`music_app/audio_output`)에 지금 출력 기기를 묻는다.
/// 다른 플랫폼이나 실패는 null(모름)로 본다.
class AudioOutputSource {
  AudioOutputSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/audio_output');

  final MethodChannel _channel;

  /// `{type: speaker|wired|bluetooth|usb|other, name: String}`
  Future<Map<String, String>?> current() async {
    try {
      final map = await _channel.invokeMapMethod<String, String>('current');
      return map;
    } on Exception {
      return null;
    }
  }
}
