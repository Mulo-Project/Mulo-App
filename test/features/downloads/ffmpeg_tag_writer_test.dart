import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/cover_tag_writer.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/ffmpeg_tag_writer.dart';

void main() {
  coverExtraTests();
  test('ffmetadata: 특수문자는 앞에 역슬래시를 붙인다', () {
    final text = FfmpegTagWriter.ffmetadata({
      'TITLE': r'a=b;c#d\e',
      'LYRICS': '[00:01.00]첫 줄\n둘째 줄',
    });
    expect(text.startsWith(';FFMETADATA1\n'), isTrue);
    expect(text, contains('TITLE=${r'a\=b\;c\#d\\e'}\n'));
    expect(text, contains('LYRICS=[00:01.00]첫 줄\\\n둘째 줄\n'));
  });

  test('그림 블록: FLAC 그림 형식(앞면 커버, PNG)', () {
    final png = Uint8List.fromList([1, 2, 3, 4]);
    final b = FfmpegTagWriter.pictureBlock(png, 512, 512);
    final d = b.buffer.asByteData();
    expect(d.getUint32(0), 3);
    expect(d.getUint32(4), 'image/png'.length);
    final w = 8 + 9 + 4; // 종류 + 길이 + MIME + 설명 길이
    expect(d.getUint32(w), 512);
    expect(d.getUint32(w + 4), 512);
    expect(d.getUint32(w + 8), 32);
    expect(d.getUint32(w + 16), 4);
    expect(b.sublist(b.length - 4), [1, 2, 3, 4]);
  });
}

void coverExtraTests() {
  test('coverExtra: 원본 주소 · 확대 · 위치 · 색을 태그 글로 남긴다', () {
    final extra = coverExtra(
      CoverArt.web(
        'https://i.test/a.jpg',
        transform: const CoverTransform(scale: 2, dx: 0.1, dy: -0.2),
      ),
      null,
      0xFF112233,
    );
    expect(extra, {
      'COVER_SOURCE': 'https://i.test/a.jpg',
      'COVER_TRANSFORM': '2.0,0.1,-0.2,0.0',
      'COVER_COLOR': 'ff112233',
    });
    expect(coverExtra(null, null, null), isEmpty);
  });
}
