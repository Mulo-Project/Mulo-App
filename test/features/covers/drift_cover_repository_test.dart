import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/covers/data/repositories/drift_cover_repository.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';

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
    expect(File(first.path!).readAsBytesSync(), [1, 2, 3]);
    expect(first.path, isNot(src.path));

    final second = await store.save('track:a', src.path);
    expect(File(first.path!).existsSync(), isFalse);
    expect(await store.loadAll(), {'track:a': second});
  });

  test('remove는 기록과 파일을 지운다', () async {
    final src = File('${base.path}/pick.jpg')..writeAsBytesSync([9]);
    final stored = await store.save('playlist:x', src.path);
    await store.remove('playlist:x');
    expect(await store.loadAll(), isEmpty);
    expect(File(stored.path!).existsSync(), isFalse);
  });

  test('웹 이미지는 파일을 만들지 않고 주소와 위치만 저장한다', () async {
    const t = CoverTransform(scale: 2.5, dx: .2, dy: -.1);
    final art = await store.saveUrl(
      'track:w',
      'https://x.test/a.jpg',
      transform: t,
    );
    expect(art, const CoverArt.web('https://x.test/a.jpg', transform: t));
    expect(await store.loadAll(), {'track:w': art});
    expect(Directory('${base.path}/covers').existsSync(), isFalse);
  });

  test('saveTransform은 이미지는 두고 위치만 바꾼다', () async {
    await store.saveUrl('track:w', 'https://x.test/a.jpg');
    const t = CoverTransform(scale: 3, dx: -.3);
    await store.saveTransform('track:w', t);
    expect(
      (await store.loadAll())['track:w'],
      const CoverArt.web('https://x.test/a.jpg', transform: t),
    );
  });

  test('기기 사진을 웹 이미지로 바꾸면 복사해 둔 파일을 지운다', () async {
    final src = File('${base.path}/pick.png')..writeAsBytesSync([1]);
    final local = await store.save('track:a', src.path);
    await store.saveUrl('track:a', 'https://x.test/b.jpg');
    expect(File(local.path!).existsSync(), isFalse);
    expect((await store.loadAll())['track:a']!.isWeb, isTrue);
  });

  test('파일이 사라진 기기 사진은 불러오지 않는다', () async {
    final src = File('${base.path}/pick.png')..writeAsBytesSync([1]);
    final local = await store.save('track:a', src.path);
    File(local.path!).deleteSync();
    expect(await store.loadAll(), isEmpty);
  });
}
