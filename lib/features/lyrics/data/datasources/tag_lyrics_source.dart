import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

import '../../domain/repositories/lyrics_repository.dart';

/// 음원 파일 태그에서 가사를 읽는다. 형식 구분 · 복사 · 태그 해석은 모두 네이티브(`music_app/lyrics`의 `read`)가 하고,
/// Dart는 곡 주소만 넘기고 돌려받은 글을 쓴다.
class TagLyricsSource implements EmbeddedLyricsSource {
  TagLyricsSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/lyrics');

  final MethodChannel _channel;

  @override
  Future<String?> read(String trackUri) async {
    if (trackUri.isEmpty) return null;
    try {
      final text = (await _channel.invokeMethod<String>('read', trackUri))
          ?.trim();
      return text == null || text.isEmpty ? null : text;
    } on PlatformException catch (e) {
      debugPrint('MuloTag lyrics read failed: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
