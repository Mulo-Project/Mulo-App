import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/data/engine/local_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/server_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/subtitle_track.dart';

const _vtt = '''WEBVTT
Kind: captions

00:00:01.000 --> 00:00:03.000
첫 줄

00:00:03.000 --> 00:00:05.000
첫 줄
<c>둘째</c> 줄

00:01:05.500 --> 00:01:07.000
&amp; 셋째
''';

void main() {
  group('자막 읽기', () {
    test('WebVTT에서 태그를 지우고 앞 칸에 나온 줄은 되풀이하지 않는다', () {
      final cues = parseVtt(_vtt);
      expect(cues.map((c) => c.text), ['첫 줄', '둘째 줄', '& 셋째']);
      expect(
        cues.last.start,
        const Duration(minutes: 1, seconds: 5, milliseconds: 500),
      );
    });

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

    test('언어 고르기: 사람이 단 자막 > 자동, 선호 순서, 자동은 원어 우선', () {
      expect(
        pickSubtitleLanguage(
          manual: ['ja', 'en'],
          automatic: ['ko-orig'],
          prefer: ['ko', 'en'],
        ),
        (language: 'en', automatic: false),
      );
      expect(
        pickSubtitleLanguage(
          manual: [],
          automatic: ['en', 'ko-orig'],
          prefer: ['en'],
        ),
        (language: 'ko-orig', automatic: true),
      );
      expect(
        pickSubtitleLanguage(manual: [], automatic: [], prefer: ['ko']),
        isNull,
      );
    });
  });

  group('LocalEngine.fetchSubtitles', () {
    test('자막 목록을 읽고 고른 언어 한 벌만 받아 가사 줄로 돌려준다', () async {
      final calls = <List<String>>[];
      final engine = LocalEngine(
        makeTempDir: () => Directory.systemTemp.createTemp('mulo_sub_test_'),
        run: (_, args) async {
          calls.add(args);
          if (args.contains('--dump-single-json')) {
            return (
              exitCode: 0,
              stdout: jsonEncode({
                'subtitles': {'en': [], 'live_chat': []},
                'automatic_captions': {'ko-orig': []},
              }),
              stderr: '',
            );
          }
          final out = args[args.indexOf('-o') + 1];
          await File('$out.en.vtt').writeAsString(_vtt);
          return (exitCode: 0, stdout: '', stderr: '');
        },
      );
      final track = await engine.fetchSubtitles('https://youtu.be/x');
      expect(track?.language, 'en');
      expect(track?.automatic, isFalse);
      expect(track?.cues, hasLength(3));
      expect(
        calls.last,
        containsAllInOrder(['--write-subs', '--sub-langs', 'en']),
      );
    });

    test('자막이 없으면 받지 않고 null', () async {
      final calls = <List<String>>[];
      final engine = LocalEngine(
        run: (_, args) async {
          calls.add(args);
          return (
            exitCode: 0,
            stdout: jsonEncode({'subtitles': {}, 'automatic_captions': {}}),
            stderr: '',
          );
        },
      );
      expect(await engine.fetchSubtitles('https://youtu.be/x'), isNull);
      expect(calls, hasLength(1));
    });

    test('곡 정보에 자막 언어가 실린다', () async {
      final engine = LocalEngine(
        run: (_, _) async => (
          exitCode: 0,
          stdout: jsonEncode({
            'id': 'v',
            'title': 'T',
            'subtitles': {'ko': []},
            'automatic_captions': {'en-orig': []},
          }),
          stderr: '',
        ),
      );
      final hit = ((await engine.fetchInfo('https://x')) as VideoInfo).hit;
      expect(hit.subtitleLangs, ['ko', 'en-orig']);
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
