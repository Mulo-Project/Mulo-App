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

  /// 불러오는 폴더를 빼서 숨긴 곡. 행과 재생 기록 · 좋아요 · 재생목록 · 커버는 남기고,
  /// 다시 불러오면 숨김만 푼다. 보관함에는 보이지 않는다.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 사용자가 지정한 커버 이미지 (키: `track:<id>` · `playlist:<id>`).
@DataClassName('CoverRow')
class Covers extends Table {
  TextColumn get key => text()();

  /// 앱 폴더로 복사한 이미지 파일 경로. 웹 이미지([url])면 빈 문자열.
  TextColumn get path => text()();

  /// 웹 이미지 주소 (파일은 복사하지 않는다). 기기 사진이면 null.
  TextColumn get url => text().nullable()();

  /// 보여 줄 때의 확대 배율과 위치(칸 한 변에 대한 비율).
  RealColumn get scale => real().withDefault(const Constant(1))();
  RealColumn get dx => real().withDefault(const Constant(0))();
  RealColumn get dy => real().withDefault(const Constant(0))();

  /// 시계 방향 회전 각도(도).
  RealColumn get rotation => real().withDefault(const Constant(0))();

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

  /// 재생목록 탭의 카드 순서 (작을수록 앞). 사용자가 순서를 바꾸면 1부터 매기고, 새로 만들면 맨 뒤로 간다.
  /// 같으면 만든 순서.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

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
  int get schemaVersion => 12;

  /// [table]에 [column]이 아직 없을 때만 더한다. 빌드를 번갈아 설치하는 등으로
  /// 열은 이미 있는데 버전만 낮아 업그레이드가 다시 도는 DB도 열리게 한다.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn column,
  ) async {
    final rows = await customSelect(
      'PRAGMA table_info("${table.actualTableName}")',
    ).get();
    final exists = rows.any((r) => r.read<String>('name') == column.name);
    if (!exists) await m.addColumn(table, column);
  }

  /// 이미 최신 버전인데 열이 빠진 DB를 열 때 고친다.
  Future<void> _repairColumns(Migrator m) async {
    await _addColumnIfMissing(m, covers, covers.url);
    await _addColumnIfMissing(m, covers, covers.scale);
    await _addColumnIfMissing(m, covers, covers.dx);
    await _addColumnIfMissing(m, covers, covers.dy);
    await _addColumnIfMissing(m, covers, covers.rotation);
    await _addColumnIfMissing(m, playlists, playlists.sortOrder);
    await _addColumnIfMissing(m, tracks, tracks.hidden);
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(plays);
      if (from < 3) {
        await _addColumnIfMissing(m, tracks, tracks.genre);
        await m.createTable(playlists);
        await m.createTable(playlistTracks);
      }
      if (from < 5) await _addColumnIfMissing(m, tracks, tracks.folder);
      if (from < 6) await m.createTable(lyricsFiles);
      // 재생목록의 옛 `color_index` 열은 더 쓰지 않는다 (색은 cover_colors로).
      if (from < 7) await m.createTable(coverColors);
      // 들은 시간이 기록되지 않던 옛 재생은 곡 길이로 한 번 채운다 (이제부터는 실제 재생 시간만 쌓는다).
      if (from < 8) await customStatement(backfillListenedSql);
      // 커버에 웹 이미지 주소와 확대 · 위치를 더한다.
      if (from < 9) {
        await _addColumnIfMissing(m, covers, covers.url);
        await _addColumnIfMissing(m, covers, covers.scale);
        await _addColumnIfMissing(m, covers, covers.dx);
        await _addColumnIfMissing(m, covers, covers.dy);
      }
      // 커버 회전 각도를 더한다.
      if (from < 10) await _addColumnIfMissing(m, covers, covers.rotation);
      // 재생목록 카드 순서를 더한다 (모두 0이면 만든 순서 그대로).
      if (from < 11) {
        await _addColumnIfMissing(m, playlists, playlists.sortOrder);
      }
      // 폴더를 빼도 곡 기록을 남기도록 숨김 칸을 더한다.
      if (from < 12) await _addColumnIfMissing(m, tracks, tracks.hidden);
    },
    beforeOpen: (details) async {
      if (details.hadUpgrade || !details.wasCreated) {
        await _repairColumns(createMigrator());
      }
    },
  );
}
