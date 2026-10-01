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

/// 재생 기록 (상세 기능: 재생 기록 저장). 곡이 재생될 때마다 한 줄.
@DataClassName('PlayRow')
class Plays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  DateTimeColumn get playedAt => dateTime()();

  /// 실제로 들은 시간(ms). 재생 엔진이 붙기 전에는 0.
  IntColumn get listenedMs => integer().withDefault(const Constant(0))();
}

/// 재생목록 (상세 기능: 재생목록 관리 #20).
@DataClassName('PlaylistRow')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// 이미지가 없을 때 카드 색 (글로우 톤 번호). 안 골랐으면 null.
  IntColumn get colorIndex => integer().nullable()();

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

/// 앱 로컬 DB (drift · SQLite). 설정값은 shared_preferences, 나머지 데이터는 여기.
@DriftDatabase(tables: [Tracks, Covers, Plays, Playlists, PlaylistTracks])
class AppDatabase extends _$AppDatabase {
  /// 테스트는 [executor]에 메모리 DB를 넣는다.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'music_app'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(plays);
      if (from < 3) {
        await m.addColumn(tracks, tracks.genre);
        await m.createTable(playlists);
        await m.createTable(playlistTracks);
      }
      if (from == 3) await m.addColumn(playlists, playlists.colorIndex);
    },
  );
}
