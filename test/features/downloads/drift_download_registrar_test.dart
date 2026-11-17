import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/drift_download_registrar.dart';

void main() {
  late AppDatabase db;
  late DriftDownloadRegistrar registrar;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    registrar = DriftDownloadRegistrar(db);
  });
  tearDown(() => db.close());

  Map<String, Object?> registration({String id = 'download:d1'}) => {
    'trackId': id,
    'title': '곡',
    'artist': '가수',
    'album': '',
    'genre': '록',
    'durationMs': 180000,
    'uri': 'content://media/1',
    'folder': '/storage/emulated/0/Music/Mulo',
    'mime': 'audio/ogg',
    'addedAtSec': 1700000000,
    'playlistIds': ['p1'],
    'cover': {'url': 'https://x/c.jpg', 'path': '', 'scale': 2.0},
    'color': 0xFF112233,
    'lyricsPath': '/data/lyrics/a.lrc',
  };

  test('곡 · 재생목록 · 커버 · 색 · 가사를 한 번에 넣는다', () async {
    await registrar.register(registration());
    final track = await db.select(db.tracks).getSingle();
    expect([track.id, track.title, track.genre, track.source, track.mime], [
      'download:d1',
      '곡',
      '록',
      'download',
      'audio/ogg',
    ]);
    expect(track.hidden, isFalse);
    expect((await db.select(db.playlistTracks).getSingle()).playlistId, 'p1');
    final cover = await db.select(db.covers).getSingle();
    expect([cover.key, cover.url, cover.scale], [
      'track:download:d1',
      'https://x/c.jpg',
      2.0,
    ]);
    expect((await db.select(db.coverColors).getSingle()).color, 0xFF112233);
    expect(
      (await db.select(db.lyricsFiles).getSingle()).path,
      '/data/lyrics/a.lrc',
    );
  });

  test('같은 곡을 다시 넘겨 받아도 한 번만 들어가고, 숨겨 둔 곡은 숨김이 풀린다', () async {
    await registrar.register(registration());
    await (db.update(db.tracks)).write(
      const TracksCompanion(hidden: Value(true)),
    );
    await registrar.register(registration());
    final rows = await db.select(db.tracks).get();
    expect(rows, hasLength(1));
    expect(rows.single.hidden, isFalse);
  });
}
