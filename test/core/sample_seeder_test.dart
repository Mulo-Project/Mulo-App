import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/core/sample/sample_data.dart';
import 'package:music_download_play_app/core/sample/sample_seeder.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('보관함이 비어 있으면 샘플 곡 · 재생목록 · 재생 기록을 넣는다', () async {
    await seedSampleData(db);
    expect((await db.select(db.tracks).get()).length, SampleData.tracks.length);
    expect(
      (await db.select(db.playlists).get()).length,
      SampleData.playlists.length,
    );
    expect(await db.select(db.playlistTracks).get(), isNotEmpty);
    expect(await db.select(db.plays).get(), isNotEmpty);
  });

  test('곡이 이미 있으면 다시 넣지 않는다', () async {
    await seedSampleData(db);
    await seedSampleData(db);
    expect((await db.select(db.tracks).get()).length, SampleData.tracks.length);
    expect(
      (await db.select(db.playlists).get()).length,
      SampleData.playlists.length,
    );
  });
}
