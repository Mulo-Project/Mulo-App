import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/lyrics/data/datasources/id3_txxx_lyrics.dart';

Uint8List _frame(String id, List<int> body, {bool v4 = false}) {
  final size = body.length;
  final sizeBytes = v4
      ? [(size >> 21) & 0x7F, (size >> 14) & 0x7F, (size >> 7) & 0x7F, size & 0x7F]
      : [(size >> 24) & 0xFF, (size >> 16) & 0xFF, (size >> 8) & 0xFF, size & 0xFF];
  return Uint8List.fromList([...ascii.encode(id), ...sizeBytes, 0, 0, ...body]);
}

Uint8List _tag(List<Uint8List> frames, {int version = 3}) {
  final body = [for (final f in frames) ...f, 0, 0, 0, 0];
  final n = body.length;
  return Uint8List.fromList([
    0x49, 0x44, 0x33, version, 0, 0,
    (n >> 21) & 0x7F, (n >> 14) & 0x7F, (n >> 7) & 0x7F, n & 0x7F,
    ...body,
  ]);
}

List<int> _utf16le(String s) => [
  0xFF, 0xFE,
  for (final u in s.codeUnits) ...[u & 0xFF, u >> 8],
];

void main() {
  test('ID3v2.3 TXXX LYRICS(UTF-16)를 읽는다', () {
    const lyrics = '[00:01.00]안녕\n[00:02.00]하세요';
    final txxx = _frame('TXXX', [
      1,
      ..._utf16le('LYRICS'), 0, 0,
      ..._utf16le(lyrics), 0, 0,
    ]);
    final title = _frame('TIT2', [0, ...latin1.encode('t')]);
    expect(Id3TxxxLyrics.parse(_tag([title, txxx])), lyrics);
  });

  test('ID3v2.4 TXXX LYRICS(UTF-8)를 읽고 다른 설명의 TXXX는 건너뛴다', () {
    final other = _frame('TXXX', [3, ...utf8.encode('COVER_SOURCE'), 0, ...utf8.encode('x')], v4: true);
    final txxx = _frame('TXXX', [3, ...utf8.encode('lyrics'), 0, ...utf8.encode('가사')], v4: true);
    expect(Id3TxxxLyrics.parse(_tag([other, txxx], version: 4)), '가사');
  });

  test('가사가 없거나 ID3가 아니면 null', () {
    expect(Id3TxxxLyrics.parse(_tag([_frame('TIT2', [0, 0x74])])), isNull);
    expect(Id3TxxxLyrics.parse(Uint8List.fromList(List.filled(20, 1))), isNull);
  });
}
