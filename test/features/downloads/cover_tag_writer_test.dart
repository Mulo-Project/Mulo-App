import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/cover_tag_writer.dart';

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// 빈 ID3v2.4 머리 + 128kbps 44.1kHz MPEG1 Layer3 프레임(417바이트) 몇 개인 가짜 mp3
/// (ffmpeg가 만든 mp3처럼 ID3 태그가 이미 있다).
Uint8List _mp3() {
  final frame = Uint8List(417)..setAll(0, [0xFF, 0xFB, 0x90, 0x00]);
  const id3 = [0x49, 0x44, 0x33, 4, 0, 0, 0, 0, 0, 0];
  return Uint8List.fromList([...id3, for (var i = 0; i < 20; i++) ...frame]);
}

void main() {
  testWidgets('mp3 태그에 고른 커버를 정사각형으로 넣는다', (tester) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('cover_tag');
      addTearDown(() => dir.delete(recursive: true));
      final image = File('${dir.path}/c.png')
        ..writeAsBytesSync(await _png(320, 180));
      final audio = File('${dir.path}/a.mp3')..writeAsBytesSync(_mp3());

      final ok = await const CoverTagWriter().embed(
        audio,
        extension: 'mp3',
        cover: CoverArt.file(image.path),
      );
      expect(ok, isTrue);
      final pic = readMetadata(audio, getImage: true).pictures.single;
      expect(pic.mimetype, 'image/png');
      final codec = await ui.instantiateImageCodec(pic.bytes);
      final frame = (await codec.getNextFrame()).image;
      expect([frame.width, frame.height], [512, 512]);
    });
  });

  testWidgets('쓸 수 없는 형식 · 이미지 없음은 파일을 건드리지 않는다', (tester) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('cover_tag');
      addTearDown(() => dir.delete(recursive: true));
      final audio = File('${dir.path}/a.weba')..writeAsBytesSync(_mp3());
      final before = audio.readAsBytesSync();
      const writer = CoverTagWriter();
      expect(
        await writer.embed(
          audio,
          extension: 'weba',
          cover: const CoverArt.file('/none.png'),
        ),
        isFalse,
      );
      expect(await writer.embed(audio, extension: 'mp3'), isFalse);
      expect(audio.readAsBytesSync(), before);
    });
  });

  testWidgets('커버가 없어도 제목 · 아티스트 · 장르는 mp3 태그에 쓴다', (tester) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('cover_tag');
      addTearDown(() => dir.delete(recursive: true));
      final audio = File('${dir.path}/a.mp3')..writeAsBytesSync(_mp3());
      final ok = await const CoverTagWriter().embed(
        audio,
        extension: 'mp3',
        title: '제목',
        artist: '가수',
        genre: '팝',
      );
      expect(ok, isTrue);
      final m = readMetadata(audio, getImage: false);
      expect(m.title, '제목');
      expect(m.artist, '가수');
      expect(m.genres, ['팝']);
    });
  });
}
