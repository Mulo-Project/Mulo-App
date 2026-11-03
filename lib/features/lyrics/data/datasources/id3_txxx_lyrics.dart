import 'dart:convert';
import 'dart:typed_data';

/// mp3 ID3v2 태그의 사용자 정의 칸(TXXX) 중 설명이 `LYRICS`인 가사를 꺼낸다.
///
/// ffmpeg가 `LYRICS` 키를 표준 가사 칸(USLT)이 아닌 TXXX로 쓴 파일을 읽기 위한 대비다
/// (`audio_metadata_reader`는 USLT만 읽는다). ID3v2.3 · 2.4를 지원하고, 없거나 깨졌으면 null.
class Id3TxxxLyrics {
  const Id3TxxxLyrics._();

  /// 태그 머리(10바이트)에서 태그 전체 길이(머리 포함). ID3 태그가 아니면 null.
  static int? tagLength(Uint8List head) {
    if (head.length < 10 || head[0] != 0x49 || head[1] != 0x44 || head[2] != 0x33) {
      return null;
    }
    return 10 + _syncsafe(head, 6);
  }

  /// [tag]: 머리를 포함한 ID3v2 태그 바이트.
  static String? parse(Uint8List tag) {
    final length = tagLength(tag);
    if (length == null) return null;
    final version = tag[3];
    if (version != 3 && version != 4) return null;
    final end = length < tag.length ? length : tag.length;
    var pos = 10;
    if (tag[5] & 0x40 != 0 && pos + 4 <= end) {
      // 확장 머리: 2.4는 길이에 자기 자신(4바이트)이 들어 있고, 2.3은 들어 있지 않다.
      final size = version == 4 ? _syncsafe(tag, pos) : _u32(tag, pos) + 4;
      pos += size;
    }
    while (pos + 10 <= end) {
      if (tag[pos] == 0) break; // 채움 구간
      final id = latin1.decode(tag.sublist(pos, pos + 4), allowInvalid: true);
      final size = version == 4 ? _syncsafe(tag, pos + 4) : _u32(tag, pos + 4);
      final body = pos + 10;
      if (size <= 0 || body + size > end) break;
      if (id == 'TXXX') {
        final text = _txxx(tag.sublist(body, body + size));
        if (text != null) return text;
      }
      pos = body + size;
    }
    return null;
  }

  static String? _txxx(Uint8List b) {
    if (b.length < 2) return null;
    final enc = b[0];
    final wide = enc == 1 || enc == 2;
    final (description, next) = _readTerminated(b, 1, wide, enc);
    if (description.trim().toUpperCase() != 'LYRICS') return null;
    final value = _decode(b.sublist(next), enc).replaceAll('\u0000', '').trim();
    return value.isEmpty ? null : value;
  }

  /// [start]부터 끝 표시(1바이트 0 · 2바이트 0)까지 읽은 글과 그 다음 위치.
  static (String, int) _readTerminated(Uint8List b, int start, bool wide, int enc) {
    var i = start;
    if (wide) {
      while (i + 1 < b.length && !(b[i] == 0 && b[i + 1] == 0)) {
        i += 2;
      }
      return (_decode(b.sublist(start, i < b.length ? i : b.length), enc), i + 2);
    }
    while (i < b.length && b[i] != 0) {
      i++;
    }
    return (_decode(b.sublist(start, i), enc), i + 1);
  }

  static String _decode(Uint8List b, int enc) {
    switch (enc) {
      case 0:
        return latin1.decode(b, allowInvalid: true);
      case 3:
        return utf8.decode(b, allowMalformed: true);
      case 1:
      case 2:
        var little = false;
        var from = 0;
        if (enc == 1 && b.length >= 2) {
          if (b[0] == 0xFF && b[1] == 0xFE) {
            little = true;
            from = 2;
          } else if (b[0] == 0xFE && b[1] == 0xFF) {
            from = 2;
          }
        }
        final units = <int>[];
        for (var i = from; i + 1 < b.length; i += 2) {
          units.add(little ? b[i] | (b[i + 1] << 8) : (b[i] << 8) | b[i + 1]);
        }
        return String.fromCharCodes(units);
      default:
        return '';
    }
  }

  static int _syncsafe(Uint8List b, int i) =>
      (b[i] << 21) | (b[i + 1] << 14) | (b[i + 2] << 7) | b[i + 3];

  static int _u32(Uint8List b, int i) =>
      (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
}
