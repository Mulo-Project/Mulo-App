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

  group('형식별 쓰기 규칙', () {
    final png = Uint8List.fromList([1, 2, 3]);
    final v = TagValues(title: 'T', artist: '', coverPng: png);

    test('확장자마다 자기 형식을 고른다', () {
      expect(FfmpegFormatWriter.forExtension('MP3'), isA<Mp3FormatWriter>());
      expect(FfmpegFormatWriter.forExtension('opus'), isA<OggFormatWriter>());
      expect(FfmpegFormatWriter.forExtension('ogg'), isA<OggFormatWriter>());
      expect(FfmpegFormatWriter.forExtension('mp4'), isA<Mp4FormatWriter>());
      expect(FfmpegFormatWriter.forExtension('webm'), isA<WebmFormatWriter>());
      expect(FfmpegFormatWriter.forExtension('flac'), isNull);
    });

    test('mp3 · mp4는 커버를 그림 파일로, opus는 태그 값으로, webm은 쓰지 않는다', () {
      expect(const Mp3FormatWriter().coverAsFile, isTrue);
      expect(const Mp4FormatWriter().coverAsFile, isTrue);
      expect(const OggFormatWriter().coverAsFile, isFalse);
      expect(const WebmFormatWriter().coverAsFile, isFalse);
      expect(
        const OggFormatWriter().entries(v).keys,
        contains('METADATA_BLOCK_PICTURE'),
      );
      expect(
        const Mp3FormatWriter().entries(v).keys,
        isNot(contains('METADATA_BLOCK_PICTURE')),
      );
      expect(
        const WebmFormatWriter().entries(v).keys,
        everyElement(isNot('METADATA_BLOCK_PICTURE')),
      );
    });

    test('키 이름: 음원은 대문자, 영상은 소문자. 빈 값은 남기고 null은 뺀다', () {
      expect(const Mp3FormatWriter().entries(v), {'TITLE': 'T', 'ARTIST': ''});
      expect(const Mp4FormatWriter().entries(v), {'title': 'T', 'artist': ''});
    });
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
