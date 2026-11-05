import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/library/data/datasources/embedded_cover_source.dart';

Uint8List _block(Uint8List png) {
  final b = BytesBuilder();
  void u32(int v) =>
      b.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.big));
  u32(3);
  u32(9);
  b.add(ascii.encode('image/png'));
  u32(0);
  u32(64);
  u32(64);
  u32(32);
  u32(0);
  u32(png.length);
  b.add(png);
  return b.toBytes();
}

void main() {
  test('Vorbis 코멘트의 METADATA_BLOCK_PICTURE에서 그림 바이트를 꺼낸다', () {
    final png = Uint8List.fromList([1, 2, 3, 4, 5]);
    final picture = pictureFromVorbisComments({
      'metadata_block_picture': base64.encode(_block(png)),
    });
    expect(picture, png);
  });

  test('없거나 깨진 값이면 null', () {
    expect(pictureFromVorbisComments({'TITLE': '곡'}), isNull);
    expect(
      pictureFromVorbisComments({'METADATA_BLOCK_PICTURE': 'not-base64!!'}),
      isNull,
    );
  });
}
