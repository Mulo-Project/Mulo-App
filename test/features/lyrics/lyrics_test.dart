import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/lyrics/data/repositories/drift_lyrics_repository.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';

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
  });

  group('DriftLyricsRepository', () {
    late AppDatabase db;
    late Directory base;
    late DriftLyricsRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      base = await Directory.systemTemp.createTemp('lyrics');
      repo = DriftLyricsRepository(db, baseDir: () async => base);
    });
    tearDown(() async {
      await db.close();
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

    test('content:// 주소는 옆 파일을 찾지 않는다', () async {
      expect(await repo.load('t3', 'content://media/external/audio/1'), isNull);
    });
  });
}
