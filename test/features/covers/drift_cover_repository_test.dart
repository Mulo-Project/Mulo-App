import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/covers/data/repositories/drift_cover_repository.dart';

void main() {
  late AppDatabase db;
  late Directory base;
  late DriftCoverRepository store;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    base = await Directory.systemTemp.createTemp('covers');
    store = DriftCoverRepository(db, baseDir: () async => base);
  });
  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  test('save는 앱 폴더로 복사하고, 다시 저장하면 옛 파일을 지운다', () async {
    final src = File('${base.path}/pick.png')..writeAsBytesSync([1, 2, 3]);
    final first = await store.save('track:a', src.path);
    expect(File(first).readAsBytesSync(), [1, 2, 3]);
    expect(first, isNot(src.path));

    final second = await store.save('track:a', src.path);
    expect(File(first).existsSync(), isFalse);
    expect(await store.loadAll(), {'track:a': second});
  });

  test('remove는 기록과 파일을 지운다', () async {
    final src = File('${base.path}/pick.jpg')..writeAsBytesSync([9]);
    final stored = await store.save('playlist:x', src.path);
    await store.remove('playlist:x');
    expect(await store.loadAll(), isEmpty);
    expect(File(stored).existsSync(), isFalse);
  });
}
