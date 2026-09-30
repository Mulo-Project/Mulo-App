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

/// 앱 로컬 DB (drift · SQLite). 설정값은 shared_preferences, 나머지 데이터는 여기.
@DriftDatabase(tables: [Tracks, Covers])
class AppDatabase extends _$AppDatabase {
  /// 테스트는 [executor]에 메모리 DB를 넣는다.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'music_app'));

  @override
  int get schemaVersion => 1;
}
