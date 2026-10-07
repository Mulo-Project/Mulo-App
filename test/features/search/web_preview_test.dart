import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/data/engine/local_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_site.dart';

void main() {
  group('미리 듣기 형식 선택', () {
    Future<List<String>> argsFor(String url) async {
      late List<String> seen;
      final engine = LocalEngine(
        run: (_, args) async {
          seen = args;
          return (
            exitCode: 0,
            stdout: jsonEncode({'url': 'https://cdn/a.mp3'}),
            stderr: '',
          );
        },
      );
      await engine.resolveAudioStream(url);
      return seen;
    }

    test('웹 곡은 조각 스트림(HLS)보다 한 파일 HTTP 형식을 먼저 고른다', () async {
      final args = await argsFor('https://soundcloud.com/a/b');
      expect(
        args[args.indexOf('-f') + 1],
        startsWith('bestaudio[protocol^=http]'),
      );
    });

    test('유튜브 곡은 기존 형식 선택을 그대로 쓴다', () async {
      final args = await argsFor('https://www.youtube.com/watch?v=v');
      expect(args[args.indexOf('-f') + 1], isNot(contains('protocol')));
    });
  });

  test('MediaSite는 주소에서 사이트 이름을 알아낸다', () {
    expect(MediaSite.fromUrl('https://soundcloud.com/a/b').name, 'SoundCloud');
    expect(MediaSite.fromUrl('https://m.soundcloud.com/a').name, 'SoundCloud');
    expect(MediaSite.fromUrl('https://artist.bandcamp.com/t').name, 'Bandcamp');
    expect(MediaSite.fromUrl('https://www.example.org/x').name, 'example.org');
    expect(MediaSite.fromUrl('not a url').name, '');
  });
}
