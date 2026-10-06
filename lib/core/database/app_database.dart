import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// 보관함 곡. `uri`는 재생 주소 (Android는 content://, 데스크톱은 파일 경로).
@DataClassName('TrackRow')
class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();

  /// 장르. 모르면 빈 문자열.
  TextColumn get genre => text().withDefault(const Constant(''))();
  IntColumn get durationMs => integer()();
  TextColumn get uri => text().unique()();

  /// 파일이 들어 있는 폴더 경로. 모르면 빈 문자열.
  TextColumn get folder => text().withDefault(const Constant(''))();

  /// `device`(기기에서 불러옴) · `download`(앱에서 받음).
  TextColumn get source => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 사용자가 지정한 커버 이미지 (키: `track:<id>` · `playlist:<id>`).
@DataClassName('CoverRow')
class Covers extends Table {
  TextColumn get key => text()();

  /// 앱 폴더로 복사한 이미지 파일 경로.
  TextColumn get path => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 사용자가 고른 커버 색 (키: `track:<id>` · `album:<이름>` · `playlist:<id>`).
/// 테마와 상관없이 고른 색 그대로 쓰므로 ARGB 값을 저장한다.
@DataClassName('CoverColorRow')
class CoverColors extends Table {
  TextColumn get key => text()();
  IntColumn get color => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 사용자가 저장한 곡별 가사 (앱 폴더 `lyrics/`의 `.lrc` · `.txt` 파일 경로).
@DataClassName('LyricsFileRow')
class LyricsFiles extends Table {
  TextColumn get trackId => text()();
  TextColumn get path => text()();

  @override
  Set<Column> get primaryKey => {trackId};
}

/// 재생 기록 (상세 기능: 재생 기록 저장). 곡이 재생될 때마다 한 줄.
@DataClassName('PlayRow')
class Plays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  DateTimeColumn get playedAt => dateTime()();

  /// 실제로 재생된 시간(ms). 재생하는 동안 계속 갱신된다.
  IntColumn get listenedMs => integer().withDefault(const Constant(0))();
}

/// 재생목록 (상세 기능: 재생목록 관리 #20).
@DataClassName('PlaylistRow')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 재생목록에 담긴 곡. 곡 하나가 여러 재생목록에 들어갈 수 있다.
@DataClassName('PlaylistTrackRow')
class PlaylistTracks extends Table {
  TextColumn get playlistId => text()();
  TextColumn get trackId => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

/// 들은 시간이 0인 재생에 곡 길이를 채우는 SQL (스키마 8 보정).
const backfillListenedSql =
    'UPDATE plays SET listened_ms = COALESCE('
    '(SELECT duration_ms FROM tracks WHERE tracks.id = plays.track_id), 0) '
    'WHERE listened_ms = 0';

/// 앱 로컬 DB (drift · SQLite). 설정값은 shared_preferences, 나머지 데이터는 여기.
@DriftDatabase(
  tables: [
    Tracks,
    Covers,
    CoverColors,
    LyricsFiles,
    Plays,
    Playlists,
    PlaylistTracks,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 테스트는 [executor]에 메모리 DB를 넣는다.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'music_app'));

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(plays);
      if (from < 3) {
        await m.addColumn(tracks, tracks.genre);
        await m.createTable(playlists);
        await m.createTable(playlistTracks);
      }
      if (from < 5) await m.addColumn(tracks, tracks.folder);
      if (from < 6) await m.createTable(lyricsFiles);
      // 재생목록의 옛 `color_index` 열은 더 쓰지 않는다 (색은 cover_colors로).
      if (from < 7) await m.createTable(coverColors);
      // 들은 시간이 기록되지 않던 옛 재생은 곡 길이로 한 번 채운다 (이제부터는 실제 재생 시간만 쌓는다).
      if (from < 8) await customStatement(backfillListenedSql);
    },
  );
}
