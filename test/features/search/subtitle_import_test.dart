import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/data/engine/server_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/subtitle_track.dart';

void main() {
  group('자막 읽기', () {
    test('.lrc 글로 바꾼다 (빈 줄은 건너뜀)', () {
      const track = SubtitleTrack(
        language: 'ko',
        cues: [
          SubtitleCue(Duration(seconds: 1, milliseconds: 230), 'A'),
          SubtitleCue(Duration(seconds: 2), '  '),
          SubtitleCue(Duration(minutes: 2), 'B'),
        ],
      );
      expect(track.toLrc(), '[00:01.23]A\n[02:00.00]B');
    });

    test('효과음 줄([음악] · (박수) · ♪)만 빼고 가사는 남긴다', () {
      const track = SubtitleTrack(
        language: 'ko',
        cues: [
          SubtitleCue(Duration(seconds: 1), '[음악]'),
          SubtitleCue(Duration(seconds: 2), '(박수)'),
          SubtitleCue(Duration(seconds: 3), '♪'),
          SubtitleCue(Duration(seconds: 4), '사랑해 [oh]'),
        ],
      );
      expect(track.withoutSoundCues().cues.map((c) => c.text), ['사랑해 [oh]']);
    });

  });

  group('ServerEngine.fetchSubtitles', () {
    test('/subtitles 응답을 자막으로 읽고, 없으면(404) null', () async {
      Uri? asked;
      final ok = ServerEngine(
        baseUrl: 'https://s',
        get: (uri, _) async {
          asked = uri;
          return (
            status: 200,
            body: jsonEncode({
              'lang': 'ko',
              'auto': true,
              'cues': [
                {'startMs': 1500, 'text': '안녕'},
                {'startMs': 'x', 'text': '무시'},
              ],
            }),
          );
        },
      );
      final track = await ok.fetchSubtitles('https://youtu.be/x');
      expect(asked?.path, '/api/v1/subtitles');
      expect(asked?.queryParameters['lang'], 'ko,en');
      expect(track?.automatic, isTrue);
      expect(track?.cues, [
        const SubtitleCue(Duration(milliseconds: 1500), '안녕'),
      ]);

      final none = ServerEngine(
        baseUrl: 'https://s',
        get: (_, _) async => (status: 404, body: '{}'),
      );
      expect(await none.fetchSubtitles('https://youtu.be/x'), isNull);
    });
  });
}
