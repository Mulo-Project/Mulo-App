import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';

Future<bool> _hasColumn(AppDatabase db, String table, String column) async {
  final rows = await db.customSelect('PRAGMA table_info("$table")').get();
  return rows.any((r) => r.read<String>('name') == column);
}

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('migration');
    file = File('${dir.path}/app.db');
    // 최신 스키마로 한 번 만들었다가 닫는다.
    final db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.close();
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });

  test('열이 이미 있는데 버전만 낮은 DB도 업그레이드된다', () async {
    var db = AppDatabase(NativeDatabase(file));
    await db.customStatement('PRAGMA user_version = 10');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    expect(await _hasColumn(db, 'playlists', 'sort_order'), isTrue);
    await db.close();
  });

  test('아주 낮은 버전으로 되돌아가도 열린다', () async {
    var db = AppDatabase(NativeDatabase(file));
    await db.customStatement('PRAGMA user_version = 8');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    expect(await _hasColumn(db, 'covers', 'rotation'), isTrue);
    await db.close();
  });

  test('최신 버전인데 열이 빠진 DB는 열 때 고쳐진다', () async {
    var db = AppDatabase(NativeDatabase(file));
    await db.customStatement('ALTER TABLE playlists DROP COLUMN sort_order');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    expect(await _hasColumn(db, 'playlists', 'sort_order'), isTrue);
    await db.close();
  });
}
