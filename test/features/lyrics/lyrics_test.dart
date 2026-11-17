import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/repositories/track_tag_repository.dart';
import 'package:music_download_play_app/features/lyrics/domain/usecases/lyrics_usecases.dart';

import '../../helpers/fakes.dart';

import 'package:music_download_play_app/core/database/native_db.dart';
import 'package:music_download_play_app/features/lyrics/data/repositories/native_lyrics_repository.dart';
import 'package:music_download_play_app/features/lyrics/data/datasources/tag_lyrics_source.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_repository.dart';

class _FakeEmbedded implements EmbeddedLyricsSource {
  String? text;
  final reads = <String>[];

  @override
  Future<String?> read(String trackUri) async {
    reads.add(trackUri);
    return text;
  }
}

void main() {
  group('Lyrics.parse', () {
    test('빈 글은 가사가 아니다', () {
      expect(Lyrics.parse(''), isNull);
      expect(Lyrics.parse('  \n \r\n'), isNull);
    });

    test('시간 표시가 있으면 싱크 가사: 메타 태그는 빼고 시간 순으로 정렬한다', () {
      final l = Lyrics.parse(
        '[ar:가수]\n[ti:제목]\n[00:12.30]둘째\n[00:01.5]첫째\n[00:30]셋째\n',
      )!;
      expect(l.isSynced, isTrue);
      expect(l.lines.map((e) => e.text), ['첫째', '둘째', '셋째']);
      expect(l.lines[0].time, const Duration(seconds: 1, milliseconds: 500));
      expect(l.lines[1].time, const Duration(seconds: 12, milliseconds: 300));
      expect(l.plain, '둘째\n첫째\n셋째');
    });

    test('한 줄에 시간 표시가 여러 개면 줄을 나눠 만든다', () {
      final l = Lyrics.parse('[00:05.00][01:05.00]후렴')!;
      expect(l.lines.map((e) => e.time.inSeconds), [5, 65]);
      expect(l.lines.every((e) => e.text == '후렴'), isTrue);
    });

    test('offset 태그는 줄 시간을 앞당기고 0 밑으로는 내려가지 않는다', () {
      final l = Lyrics.parse('[offset:2000]\n[00:01.00]가\n[00:10.00]나')!;
      expect(l.lines.map((e) => e.time.inSeconds), [0, 8]);
    });

    test('시간 표시가 없으면 일반 글', () {
      final l = Lyrics.parse('첫 줄\r\n둘째 줄')!;
      expect(l.isSynced, isFalse);
      expect(l.lines, isEmpty);
      expect(l.plain, '첫 줄\n둘째 줄');
    });

    test('currentLine은 재생 위치에 맞는 줄 번호', () {
      final l = Lyrics.parse('[00:10.00]가\n[00:20.00]나')!;
      expect(l.currentLine(const Duration(seconds: 5)), -1);
      expect(l.currentLine(const Duration(seconds: 10)), 0);
      expect(l.currentLine(const Duration(seconds: 19)), 0);
      expect(l.currentLine(const Duration(seconds: 99)), 1);
    });

    test('groupAt은 같은 시간으로 묶인 이웃 줄의 범위', () {
      final l = Lyrics.parse(
        '[00:10.00]가\n[00:10.00]나\n[00:10.00]다\n[00:20.00]라\n[00:30.00]마',
      )!;
      // 묶인 줄은 재생 위치가 닿으면 맨 끝 줄이 현재 줄이지만, 범위는 처음부터 끝까지다.
      expect(l.currentLine(const Duration(seconds: 15)), 2);
      expect(l.groupAt(2), (0, 2));
      expect(l.groupAt(0), (0, 2));
      expect(l.groupAt(3), (3, 3));
      expect(l.groupAt(-1), (-1, -1));
    });
  });

  group('NativeLyricsRepository', () {
    late Directory base;
    late NativeLyricsRepository repo;
    late _FakeEmbedded embedded;

    /// 네이티브 DB 대신 경로만 기억하는 가짜 채널 (실제 저장과 옛 파일 정리는 네이티브가 한다).
    final paths = <String, String>{};
    const channel = MethodChannel('test/db');

    setUp(() async {
      embedded = _FakeEmbedded();
      paths.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final args = call.arguments as Map<Object?, Object?>;
            final id = args['trackId']! as String;
            switch (call.method) {
              case 'lyricsPath':
                return paths[id];
              case 'saveLyricsPath':
                final old = paths[id];
                paths[id] = args['path']! as String;
                if (old != null && old != paths[id]) {
                  final f = File(old);
                  if (f.existsSync()) f.deleteSync();
                }
              case 'removeLyrics':
                final old = paths.remove(id);
                if (old != null) {
                  final f = File(old);
                  if (f.existsSync()) f.deleteSync();
                }
            }
            return null;
          });
      base = await Directory.systemTemp.createTemp('lyrics');
      repo = NativeLyricsRepository(
        NativeDb(channel: channel),
        embedded,
        baseDir: () async => base,
      );
    });
    tearDown(() async {
      await base.delete(recursive: true);
    });

    test('저장한 가사는 다시 불러오고, 싱크 ↔ 일반 글이 바뀌면 옛 파일을 지운다', () async {
      await repo.save('t1', '[00:01.00]가');
      final lrc = File('${base.path}/lyrics/t1.lrc');
      expect(lrc.existsSync(), isTrue);
      expect((await repo.load('t1', ''))!.isSynced, isTrue);

      await repo.save('t1', '그냥 글');
      expect(lrc.existsSync(), isFalse);
      expect(File('${base.path}/lyrics/t1.txt').existsSync(), isTrue);
      expect((await repo.load('t1', ''))!.plain, '그냥 글');
    });

    test('빈 글로 저장하면 지운다', () async {
      await repo.save('t1', '가사');
      expect(await repo.save('t1', '  '), isNull);
      expect(await repo.load('t1', ''), isNull);
      expect(Directory('${base.path}/lyrics').listSync(), isEmpty);
    });

    test('저장한 가사가 없으면 음원 옆 같은 이름 .lrc를 쓴다 (저장한 가사가 우선)', () async {
      final song = File('${base.path}/노래.mp3')..writeAsBytesSync([0]);
      File('${base.path}/노래.lrc').writeAsStringSync('﻿[00:02.00]옆 파일');

      final side = await repo.load('t2', song.path);
      expect(side!.lines.single.text, '옆 파일');

      await repo.save('t2', '[00:01.00]내가 넣음');
      expect((await repo.load('t2', song.path))!.lines.single.text, '내가 넣음');
    });

    test('옆 파일도 없으면 파일 태그 속 가사 (앞의 두 곳이 우선이라 그땐 읽지 않는다)', () async {
      embedded.text = '[00:03.00]태그 가사';
      expect((await repo.load('t4', '/a/b.mp3'))!.lines.single.text, '태그 가사');
      expect(embedded.reads, ['/a/b.mp3']);

      await repo.save('t4', '직접');
      embedded.reads.clear();
      expect((await repo.load('t4', '/a/b.mp3'))!.plain, '직접');
      expect(embedded.reads, isEmpty);
    });

    test('content:// 주소는 옆 파일을 찾지 않는다', () async {
      expect(await repo.load('t3', 'content://media/external/audio/1'), isNull);
    });
  });

  group('TagLyricsSource', () {
    late MethodChannel channel;
    String? reply;
    final calls = <Object?>[];

    setUp(() {
      channel = const MethodChannel('test/lyrics');
      calls.clear();
      reply = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.arguments);
            return reply;
          });
    });

    test('곡 주소를 네이티브에 넘기고 돌려받은 글을 쓴다', () async {
      reply = ' [00:01.00]hello \n';
      final text = await TagLyricsSource(channel: channel).read('/a.mp3');
      expect(text, '[00:01.00]hello');
      expect(calls, ['/a.mp3']);
    });

    test('네이티브가 가사 없음(null · 빈 글)이거나 주소가 비면 null', () async {
      expect(await TagLyricsSource(channel: channel).read('/b.mp3'), isNull);
      reply = '  ';
      expect(await TagLyricsSource(channel: channel).read('/b.mp3'), isNull);
      expect(await TagLyricsSource(channel: channel).read(''), isNull);
    });
  });

  group('SaveLyrics', () {
    final track = Track(
      id: 't1',
      title: 'T',
      artist: 'A',
      album: '',
      duration: Duration.zero,
      uri: '/m/t1.mp3',
      addedAt: DateTime(2026, 10, 1),
    );

    test('가사를 앱에 저장하고 음원 파일의 가사 태그에도 쓴다', () async {
      final repo = MemoryLyricsRepository();
      final tags = FakeTrackTagRepository();
      final saved = await SaveLyrics(
        repo,
        tags,
      )(SaveLyricsParams(track, '[00:01.00]hi'));
      await saved.tag;
      expect(repo.saved['t1'], '[00:01.00]hi');
      expect(tags.lyricsWritten['t1'], '[00:01.00]hi');
    });

    test('파일 태그 쓰기 결과를 돌려준다', () async {
      final repo = MemoryLyricsRepository();
      final tags = FakeTrackTagRepository()..result = TagWriteResult.denied;
      final saved = await SaveLyrics(
        repo,
        tags,
      )(SaveLyricsParams(track, '[00:01.00]hi'));
      expect(saved.lyrics, isNotNull);
      expect((await saved.tag)?.result, TagWriteResult.denied);
    });

    test('가사를 비우면 파일 태그는 건드리지 않는다', () async {
      final repo = MemoryLyricsRepository();
      final tags = FakeTrackTagRepository();
      await SaveLyrics(repo, tags)(SaveLyricsParams(track, '  '));
      expect(tags.lyricsWritten, isEmpty);
    });
  });
}
