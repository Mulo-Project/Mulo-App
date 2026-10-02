import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/covers/data/repositories/drift_cover_color_repository.dart';

void main() {
  late AppDatabase db;
  late DriftCoverColorRepository store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftCoverColorRepository(db);
  });
  tearDown(() => db.close());

  test('곡 · 앨범 · 재생목록 색을 저장하고 덮어쓰고 지운다', () async {
    await store.save('track:a', 0xFFE5484D);
    await store.save('album:앨범', 0xFF3E63DD);
    await store.save('playlist:p', 0xFF12A594);
    await store.save('track:a', 0xFF7C5CE0);

    expect(await store.loadAll(), {
      'track:a': 0xFF7C5CE0,
      'album:앨범': 0xFF3E63DD,
      'playlist:p': 0xFF12A594,
    });

    await store.remove('track:a');
    expect((await store.loadAll()).containsKey('track:a'), isFalse);
  });
}
