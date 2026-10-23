// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, TrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artist,
    album,
    genre,
    durationMs,
    uri,
    folder,
    source,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    } else if (isInserting) {
      context.missing(_albumMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class TrackRow extends DataClass implements Insertable<TrackRow> {
  final String id;
  final String title;
  final String artist;
  final String album;

  /// 장르. 모르면 빈 문자열.
  final String genre;
  final int durationMs;
  final String uri;

  /// 파일이 들어 있는 폴더 경로. 모르면 빈 문자열.
  final String folder;

  /// `device`(기기에서 불러옴) · `download`(앱에서 받음).
  final String source;
  final DateTime addedAt;
  const TrackRow({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.durationMs,
    required this.uri,
    required this.folder,
    required this.source,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    map['genre'] = Variable<String>(genre);
    map['duration_ms'] = Variable<int>(durationMs);
    map['uri'] = Variable<String>(uri);
    map['folder'] = Variable<String>(folder);
    map['source'] = Variable<String>(source);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      title: Value(title),
      artist: Value(artist),
      album: Value(album),
      genre: Value(genre),
      durationMs: Value(durationMs),
      uri: Value(uri),
      folder: Value(folder),
      source: Value(source),
      addedAt: Value(addedAt),
    );
  }

  factory TrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      genre: serializer.fromJson<String>(json['genre']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      uri: serializer.fromJson<String>(json['uri']),
      folder: serializer.fromJson<String>(json['folder']),
      source: serializer.fromJson<String>(json['source']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'genre': serializer.toJson<String>(genre),
      'durationMs': serializer.toJson<int>(durationMs),
      'uri': serializer.toJson<String>(uri),
      'folder': serializer.toJson<String>(folder),
      'source': serializer.toJson<String>(source),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  TrackRow copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? durationMs,
    String? uri,
    String? folder,
    String? source,
    DateTime? addedAt,
  }) => TrackRow(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    genre: genre ?? this.genre,
    durationMs: durationMs ?? this.durationMs,
    uri: uri ?? this.uri,
    folder: folder ?? this.folder,
    source: source ?? this.source,
    addedAt: addedAt ?? this.addedAt,
  );
  TrackRow copyWithCompanion(TracksCompanion data) {
    return TrackRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      genre: data.genre.present ? data.genre.value : this.genre,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      uri: data.uri.present ? data.uri.value : this.uri,
      folder: data.folder.present ? data.folder.value : this.folder,
      source: data.source.present ? data.source.value : this.source,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('genre: $genre, ')
          ..write('durationMs: $durationMs, ')
          ..write('uri: $uri, ')
          ..write('folder: $folder, ')
          ..write('source: $source, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    artist,
    album,
    genre,
    durationMs,
    uri,
    folder,
    source,
    addedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.genre == this.genre &&
          other.durationMs == this.durationMs &&
          other.uri == this.uri &&
          other.folder == this.folder &&
          other.source == this.source &&
          other.addedAt == this.addedAt);
}

class TracksCompanion extends UpdateCompanion<TrackRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> album;
  final Value<String> genre;
  final Value<int> durationMs;
  final Value<String> uri;
  final Value<String> folder;
  final Value<String> source;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.genre = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.uri = const Value.absent(),
    this.folder = const Value.absent(),
    this.source = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String id,
    required String title,
    required String artist,
    required String album,
    this.genre = const Value.absent(),
    required int durationMs,
    required String uri,
    this.folder = const Value.absent(),
    required String source,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       artist = Value(artist),
       album = Value(album),
       durationMs = Value(durationMs),
       uri = Value(uri),
       source = Value(source),
       addedAt = Value(addedAt);
  static Insertable<TrackRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? genre,
    Expression<int>? durationMs,
    Expression<String>? uri,
    Expression<String>? folder,
    Expression<String>? source,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (genre != null) 'genre': genre,
      if (durationMs != null) 'duration_ms': durationMs,
      if (uri != null) 'uri': uri,
      if (folder != null) 'folder': folder,
      if (source != null) 'source': source,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? artist,
    Value<String>? album,
    Value<String>? genre,
    Value<int>? durationMs,
    Value<String>? uri,
    Value<String>? folder,
    Value<String>? source,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      uri: uri ?? this.uri,
      folder: folder ?? this.folder,
      source: source ?? this.source,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('genre: $genre, ')
          ..write('durationMs: $durationMs, ')
          ..write('uri: $uri, ')
          ..write('folder: $folder, ')
          ..write('source: $source, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoversTable extends Covers with TableInfo<$CoversTable, CoverRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<double> scale = GeneratedColumn<double>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dxMeta = const VerificationMeta('dx');
  @override
  late final GeneratedColumn<double> dx = GeneratedColumn<double>(
    'dx',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dyMeta = const VerificationMeta('dy');
  @override
  late final GeneratedColumn<double> dy = GeneratedColumn<double>(
    'dy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    path,
    url,
    scale,
    dx,
    dy,
    rotation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'covers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoverRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('dx')) {
      context.handle(_dxMeta, dx.isAcceptableOrUnknown(data['dx']!, _dxMeta));
    }
    if (data.containsKey('dy')) {
      context.handle(_dyMeta, dy.isAcceptableOrUnknown(data['dy']!, _dyMeta));
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CoverRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoverRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scale'],
      )!,
      dx: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dx'],
      )!,
      dy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dy'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
    );
  }

  @override
  $CoversTable createAlias(String alias) {
    return $CoversTable(attachedDatabase, alias);
  }
}

class CoverRow extends DataClass implements Insertable<CoverRow> {
  final String key;

  /// 앱 폴더로 복사한 이미지 파일 경로. 웹 이미지([url])면 빈 문자열.
  final String path;

  /// 웹 이미지 주소 (파일은 복사하지 않는다). 기기 사진이면 null.
  final String? url;

  /// 보여 줄 때의 확대 배율과 위치(칸 한 변에 대한 비율).
  final double scale;
  final double dx;
  final double dy;

  /// 시계 방향 회전 각도(도).
  final double rotation;
  const CoverRow({
    required this.key,
    required this.path,
    this.url,
    required this.scale,
    required this.dx,
    required this.dy,
    required this.rotation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['scale'] = Variable<double>(scale);
    map['dx'] = Variable<double>(dx);
    map['dy'] = Variable<double>(dy);
    map['rotation'] = Variable<double>(rotation);
    return map;
  }

  CoversCompanion toCompanion(bool nullToAbsent) {
    return CoversCompanion(
      key: Value(key),
      path: Value(path),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      scale: Value(scale),
      dx: Value(dx),
      dy: Value(dy),
      rotation: Value(rotation),
    );
  }

  factory CoverRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoverRow(
      key: serializer.fromJson<String>(json['key']),
      path: serializer.fromJson<String>(json['path']),
      url: serializer.fromJson<String?>(json['url']),
      scale: serializer.fromJson<double>(json['scale']),
      dx: serializer.fromJson<double>(json['dx']),
      dy: serializer.fromJson<double>(json['dy']),
      rotation: serializer.fromJson<double>(json['rotation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'path': serializer.toJson<String>(path),
      'url': serializer.toJson<String?>(url),
      'scale': serializer.toJson<double>(scale),
      'dx': serializer.toJson<double>(dx),
      'dy': serializer.toJson<double>(dy),
      'rotation': serializer.toJson<double>(rotation),
    };
  }

  CoverRow copyWith({
    String? key,
    String? path,
    Value<String?> url = const Value.absent(),
    double? scale,
    double? dx,
    double? dy,
    double? rotation,
  }) => CoverRow(
    key: key ?? this.key,
    path: path ?? this.path,
    url: url.present ? url.value : this.url,
    scale: scale ?? this.scale,
    dx: dx ?? this.dx,
    dy: dy ?? this.dy,
    rotation: rotation ?? this.rotation,
  );
  CoverRow copyWithCompanion(CoversCompanion data) {
    return CoverRow(
      key: data.key.present ? data.key.value : this.key,
      path: data.path.present ? data.path.value : this.path,
      url: data.url.present ? data.url.value : this.url,
      scale: data.scale.present ? data.scale.value : this.scale,
      dx: data.dx.present ? data.dx.value : this.dx,
      dy: data.dy.present ? data.dy.value : this.dy,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoverRow(')
          ..write('key: $key, ')
          ..write('path: $path, ')
          ..write('url: $url, ')
          ..write('scale: $scale, ')
          ..write('dx: $dx, ')
          ..write('dy: $dy, ')
          ..write('rotation: $rotation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, path, url, scale, dx, dy, rotation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoverRow &&
          other.key == this.key &&
          other.path == this.path &&
          other.url == this.url &&
          other.scale == this.scale &&
          other.dx == this.dx &&
          other.dy == this.dy &&
          other.rotation == this.rotation);
}

class CoversCompanion extends UpdateCompanion<CoverRow> {
  final Value<String> key;
  final Value<String> path;
  final Value<String?> url;
  final Value<double> scale;
  final Value<double> dx;
  final Value<double> dy;
  final Value<double> rotation;
  final Value<int> rowid;
  const CoversCompanion({
    this.key = const Value.absent(),
    this.path = const Value.absent(),
    this.url = const Value.absent(),
    this.scale = const Value.absent(),
    this.dx = const Value.absent(),
    this.dy = const Value.absent(),
    this.rotation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoversCompanion.insert({
    required String key,
    required String path,
    this.url = const Value.absent(),
    this.scale = const Value.absent(),
    this.dx = const Value.absent(),
    this.dy = const Value.absent(),
    this.rotation = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       path = Value(path);
  static Insertable<CoverRow> custom({
    Expression<String>? key,
    Expression<String>? path,
    Expression<String>? url,
    Expression<double>? scale,
    Expression<double>? dx,
    Expression<double>? dy,
    Expression<double>? rotation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (path != null) 'path': path,
      if (url != null) 'url': url,
      if (scale != null) 'scale': scale,
      if (dx != null) 'dx': dx,
      if (dy != null) 'dy': dy,
      if (rotation != null) 'rotation': rotation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoversCompanion copyWith({
    Value<String>? key,
    Value<String>? path,
    Value<String?>? url,
    Value<double>? scale,
    Value<double>? dx,
    Value<double>? dy,
    Value<double>? rotation,
    Value<int>? rowid,
  }) {
    return CoversCompanion(
      key: key ?? this.key,
      path: path ?? this.path,
      url: url ?? this.url,
      scale: scale ?? this.scale,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      rotation: rotation ?? this.rotation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (scale.present) {
      map['scale'] = Variable<double>(scale.value);
    }
    if (dx.present) {
      map['dx'] = Variable<double>(dx.value);
    }
    if (dy.present) {
      map['dy'] = Variable<double>(dy.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoversCompanion(')
          ..write('key: $key, ')
          ..write('path: $path, ')
          ..write('url: $url, ')
          ..write('scale: $scale, ')
          ..write('dx: $dx, ')
          ..write('dy: $dy, ')
          ..write('rotation: $rotation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoverColorsTable extends CoverColors
    with TableInfo<$CoverColorsTable, CoverColorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoverColorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cover_colors';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoverColorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CoverColorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoverColorRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
    );
  }

  @override
  $CoverColorsTable createAlias(String alias) {
    return $CoverColorsTable(attachedDatabase, alias);
  }
}

class CoverColorRow extends DataClass implements Insertable<CoverColorRow> {
  final String key;
  final int color;
  const CoverColorRow({required this.key, required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['color'] = Variable<int>(color);
    return map;
  }

  CoverColorsCompanion toCompanion(bool nullToAbsent) {
    return CoverColorsCompanion(key: Value(key), color: Value(color));
  }

  factory CoverColorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoverColorRow(
      key: serializer.fromJson<String>(json['key']),
      color: serializer.fromJson<int>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'color': serializer.toJson<int>(color),
    };
  }

  CoverColorRow copyWith({String? key, int? color}) =>
      CoverColorRow(key: key ?? this.key, color: color ?? this.color);
  CoverColorRow copyWithCompanion(CoverColorsCompanion data) {
    return CoverColorRow(
      key: data.key.present ? data.key.value : this.key,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoverColorRow(')
          ..write('key: $key, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoverColorRow &&
          other.key == this.key &&
          other.color == this.color);
}

class CoverColorsCompanion extends UpdateCompanion<CoverColorRow> {
  final Value<String> key;
  final Value<int> color;
  final Value<int> rowid;
  const CoverColorsCompanion({
    this.key = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoverColorsCompanion.insert({
    required String key,
    required int color,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       color = Value(color);
  static Insertable<CoverColorRow> custom({
    Expression<String>? key,
    Expression<int>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoverColorsCompanion copyWith({
    Value<String>? key,
    Value<int>? color,
    Value<int>? rowid,
  }) {
    return CoverColorsCompanion(
      key: key ?? this.key,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoverColorsCompanion(')
          ..write('key: $key, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LyricsFilesTable extends LyricsFiles
    with TableInfo<$LyricsFilesTable, LyricsFileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LyricsFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, path];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<LyricsFileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  LyricsFileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LyricsFileRow(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
    );
  }

  @override
  $LyricsFilesTable createAlias(String alias) {
    return $LyricsFilesTable(attachedDatabase, alias);
  }
}

class LyricsFileRow extends DataClass implements Insertable<LyricsFileRow> {
  final String trackId;
  final String path;
  const LyricsFileRow({required this.trackId, required this.path});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['path'] = Variable<String>(path);
    return map;
  }

  LyricsFilesCompanion toCompanion(bool nullToAbsent) {
    return LyricsFilesCompanion(trackId: Value(trackId), path: Value(path));
  }

  factory LyricsFileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LyricsFileRow(
      trackId: serializer.fromJson<String>(json['trackId']),
      path: serializer.fromJson<String>(json['path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'path': serializer.toJson<String>(path),
    };
  }

  LyricsFileRow copyWith({String? trackId, String? path}) =>
      LyricsFileRow(trackId: trackId ?? this.trackId, path: path ?? this.path);
  LyricsFileRow copyWithCompanion(LyricsFilesCompanion data) {
    return LyricsFileRow(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      path: data.path.present ? data.path.value : this.path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LyricsFileRow(')
          ..write('trackId: $trackId, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, path);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricsFileRow &&
          other.trackId == this.trackId &&
          other.path == this.path);
}

class LyricsFilesCompanion extends UpdateCompanion<LyricsFileRow> {
  final Value<String> trackId;
  final Value<String> path;
  final Value<int> rowid;
  const LyricsFilesCompanion({
    this.trackId = const Value.absent(),
    this.path = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LyricsFilesCompanion.insert({
    required String trackId,
    required String path,
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       path = Value(path);
  static Insertable<LyricsFileRow> custom({
    Expression<String>? trackId,
    Expression<String>? path,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (path != null) 'path': path,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LyricsFilesCompanion copyWith({
    Value<String>? trackId,
    Value<String>? path,
    Value<int>? rowid,
  }) {
    return LyricsFilesCompanion(
      trackId: trackId ?? this.trackId,
      path: path ?? this.path,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LyricsFilesCompanion(')
          ..write('trackId: $trackId, ')
          ..write('path: $path, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaysTable extends Plays with TableInfo<$PlaysTable, PlayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenedMsMeta = const VerificationMeta(
    'listenedMs',
  );
  @override
  late final GeneratedColumn<int> listenedMs = GeneratedColumn<int>(
    'listened_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, trackId, playedAt, listenedMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plays';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('listened_ms')) {
      context.handle(
        _listenedMsMeta,
        listenedMs.isAcceptableOrUnknown(data['listened_ms']!, _listenedMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
      listenedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listened_ms'],
      )!,
    );
  }

  @override
  $PlaysTable createAlias(String alias) {
    return $PlaysTable(attachedDatabase, alias);
  }
}

class PlayRow extends DataClass implements Insertable<PlayRow> {
  final int id;
  final String trackId;
  final DateTime playedAt;

  /// 실제로 재생된 시간(ms). 재생하는 동안 계속 갱신된다.
  final int listenedMs;
  const PlayRow({
    required this.id,
    required this.trackId,
    required this.playedAt,
    required this.listenedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<String>(trackId);
    map['played_at'] = Variable<DateTime>(playedAt);
    map['listened_ms'] = Variable<int>(listenedMs);
    return map;
  }

  PlaysCompanion toCompanion(bool nullToAbsent) {
    return PlaysCompanion(
      id: Value(id),
      trackId: Value(trackId),
      playedAt: Value(playedAt),
      listenedMs: Value(listenedMs),
    );
  }

  factory PlayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayRow(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      listenedMs: serializer.fromJson<int>(json['listenedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String>(trackId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'listenedMs': serializer.toJson<int>(listenedMs),
    };
  }

  PlayRow copyWith({
    int? id,
    String? trackId,
    DateTime? playedAt,
    int? listenedMs,
  }) => PlayRow(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    playedAt: playedAt ?? this.playedAt,
    listenedMs: listenedMs ?? this.listenedMs,
  );
  PlayRow copyWithCompanion(PlaysCompanion data) {
    return PlayRow(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      listenedMs: data.listenedMs.present
          ? data.listenedMs.value
          : this.listenedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayRow(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt, ')
          ..write('listenedMs: $listenedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, playedAt, listenedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayRow &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.playedAt == this.playedAt &&
          other.listenedMs == this.listenedMs);
}

class PlaysCompanion extends UpdateCompanion<PlayRow> {
  final Value<int> id;
  final Value<String> trackId;
  final Value<DateTime> playedAt;
  final Value<int> listenedMs;
  const PlaysCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.listenedMs = const Value.absent(),
  });
  PlaysCompanion.insert({
    this.id = const Value.absent(),
    required String trackId,
    required DateTime playedAt,
    this.listenedMs = const Value.absent(),
  }) : trackId = Value(trackId),
       playedAt = Value(playedAt);
  static Insertable<PlayRow> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<DateTime>? playedAt,
    Expression<int>? listenedMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (playedAt != null) 'played_at': playedAt,
      if (listenedMs != null) 'listened_ms': listenedMs,
    });
  }

  PlaysCompanion copyWith({
    Value<int>? id,
    Value<String>? trackId,
    Value<DateTime>? playedAt,
    Value<int>? listenedMs,
  }) {
    return PlaysCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      playedAt: playedAt ?? this.playedAt,
      listenedMs: listenedMs ?? this.listenedMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (listenedMs.present) {
      map['listened_ms'] = Variable<int>(listenedMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaysCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt, ')
          ..write('listenedMs: $listenedMs')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, PlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class PlaylistRow extends DataClass implements Insertable<PlaylistRow> {
  final String id;
  final String name;
  final DateTime createdAt;

  /// 재생목록 탭의 카드 순서 (작을수록 앞). 사용자가 순서를 바꾸면 1부터 매기고, 새로 만들면 맨 뒤로 간다.
  /// 같으면 만든 순서.
  final int sortOrder;
  const PlaylistRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory PlaylistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PlaylistRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? sortOrder,
  }) => PlaylistRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  PlaylistRow copyWithCompanion(PlaylistsCompanion data) {
    return PlaylistRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.sortOrder == this.sortOrder);
}

class PlaylistsCompanion extends UpdateCompanion<PlaylistRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<PlaylistRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTracksTable extends PlaylistTracks
    with TableInfo<$PlaylistTracksTable, PlaylistTrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, trackId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistTrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, trackId};
  @override
  PlaylistTrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrackRow(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $PlaylistTracksTable createAlias(String alias) {
    return $PlaylistTracksTable(attachedDatabase, alias);
  }
}

class PlaylistTrackRow extends DataClass
    implements Insertable<PlaylistTrackRow> {
  final String playlistId;
  final String trackId;
  final DateTime addedAt;
  const PlaylistTrackRow({
    required this.playlistId,
    required this.trackId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['track_id'] = Variable<String>(trackId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  PlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTracksCompanion(
      playlistId: Value(playlistId),
      trackId: Value(trackId),
      addedAt: Value(addedAt),
    );
  }

  factory PlaylistTrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrackRow(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'trackId': serializer.toJson<String>(trackId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  PlaylistTrackRow copyWith({
    String? playlistId,
    String? trackId,
    DateTime? addedAt,
  }) => PlaylistTrackRow(
    playlistId: playlistId ?? this.playlistId,
    trackId: trackId ?? this.trackId,
    addedAt: addedAt ?? this.addedAt,
  );
  PlaylistTrackRow copyWithCompanion(PlaylistTracksCompanion data) {
    return PlaylistTrackRow(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrackRow(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, trackId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrackRow &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.addedAt == this.addedAt);
}

class PlaylistTracksCompanion extends UpdateCompanion<PlaylistTrackRow> {
  final Value<String> playlistId;
  final Value<String> trackId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const PlaylistTracksCompanion({
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistTracksCompanion.insert({
    required String playlistId,
    required String trackId,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackId = Value(trackId),
       addedAt = Value(addedAt);
  static Insertable<PlaylistTrackRow> custom({
    Expression<String>? playlistId,
    Expression<String>? trackId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistTracksCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? trackId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return PlaylistTracksCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTracksCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $CoversTable covers = $CoversTable(this);
  late final $CoverColorsTable coverColors = $CoverColorsTable(this);
  late final $LyricsFilesTable lyricsFiles = $LyricsFilesTable(this);
  late final $PlaysTable plays = $PlaysTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistTracksTable playlistTracks = $PlaylistTracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tracks,
    covers,
    coverColors,
    lyricsFiles,
    plays,
    playlists,
    playlistTracks,
  ];
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  required String id,
  required String title,
  required String artist,
  required String album,
  Value<String> genre,
  required int durationMs,
  required String uri,
  Value<String> folder,
  required String source,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> artist,
  Value<String> album,
  Value<String> genre,
  Value<int> durationMs,
  Value<String> uri,
  Value<String> folder,
  Value<String> source,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          TrackRow,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (TrackRow, BaseReferences<_$AppDatabase, $TracksTable, TrackRow>),
          TrackRow,
          PrefetchHooks Function()
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> album = const Value.absent(),
                Value<String> genre = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> folder = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                title: title,
                artist: artist,
                album: album,
                genre: genre,
                durationMs: durationMs,
                uri: uri,
                folder: folder,
                source: source,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String artist,
                required String album,
                Value<String> genre = const Value.absent(),
                required int durationMs,
                required String uri,
                Value<String> folder = const Value.absent(),
                required String source,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                title: title,
                artist: artist,
                album: album,
                genre: genre,
                durationMs: durationMs,
                uri: uri,
                folder: folder,
                source: source,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracksTable, TrackRow>(table),
                  BaseReferences<_$AppDatabase, $TracksTable, TrackRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      TrackRow,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (TrackRow, BaseReferences<_$AppDatabase, $TracksTable, TrackRow>),
      TrackRow,
      PrefetchHooks Function()
    >;
typedef $$CoversTableCreateCompanionBuilder = CoversCompanion Function({
  required String key,
  required String path,
  Value<String?> url,
  Value<double> scale,
  Value<double> dx,
  Value<double> dy,
  Value<double> rotation,
  Value<int> rowid,
});
typedef $$CoversTableUpdateCompanionBuilder = CoversCompanion Function({
  Value<String> key,
  Value<String> path,
  Value<String?> url,
  Value<double> scale,
  Value<double> dx,
  Value<double> dy,
  Value<double> rotation,
  Value<int> rowid,
});

class $$CoversTableFilterComposer
    extends Composer<_$AppDatabase, $CoversTable> {
  $$CoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dx => $composableBuilder(
    column: $table.dx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dy => $composableBuilder(
    column: $table.dy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoversTableOrderingComposer
    extends Composer<_$AppDatabase, $CoversTable> {
  $$CoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dx => $composableBuilder(
    column: $table.dx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dy => $composableBuilder(
    column: $table.dy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoversTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoversTable> {
  $$CoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<double> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<double> get dx =>
      $composableBuilder(column: $table.dx, builder: (column) => column);

  GeneratedColumn<double> get dy =>
      $composableBuilder(column: $table.dy, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);
}

class $$CoversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoversTable,
          CoverRow,
          $$CoversTableFilterComposer,
          $$CoversTableOrderingComposer,
          $$CoversTableAnnotationComposer,
          $$CoversTableCreateCompanionBuilder,
          $$CoversTableUpdateCompanionBuilder,
          (CoverRow, BaseReferences<_$AppDatabase, $CoversTable, CoverRow>),
          CoverRow,
          PrefetchHooks Function()
        > {
  $$CoversTableTableManager(_$AppDatabase db, $CoversTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<double> scale = const Value.absent(),
                Value<double> dx = const Value.absent(),
                Value<double> dy = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoversCompanion(
                key: key,
                path: path,
                url: url,
                scale: scale,
                dx: dx,
                dy: dy,
                rotation: rotation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String path,
                Value<String?> url = const Value.absent(),
                Value<double> scale = const Value.absent(),
                Value<double> dx = const Value.absent(),
                Value<double> dy = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoversCompanion.insert(
                key: key,
                path: path,
                url: url,
                scale: scale,
                dx: dx,
                dy: dy,
                rotation: rotation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoversTable, CoverRow>(table),
                  BaseReferences<_$AppDatabase, $CoversTable, CoverRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoversTable,
      CoverRow,
      $$CoversTableFilterComposer,
      $$CoversTableOrderingComposer,
      $$CoversTableAnnotationComposer,
      $$CoversTableCreateCompanionBuilder,
      $$CoversTableUpdateCompanionBuilder,
      (CoverRow, BaseReferences<_$AppDatabase, $CoversTable, CoverRow>),
      CoverRow,
      PrefetchHooks Function()
    >;
typedef $$CoverColorsTableCreateCompanionBuilder =
    CoverColorsCompanion Function({
      required String key,
      required int color,
      Value<int> rowid,
    });
typedef $$CoverColorsTableUpdateCompanionBuilder =
    CoverColorsCompanion Function({
      Value<String> key,
      Value<int> color,
      Value<int> rowid,
    });

class $$CoverColorsTableFilterComposer
    extends Composer<_$AppDatabase, $CoverColorsTable> {
  $$CoverColorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoverColorsTableOrderingComposer
    extends Composer<_$AppDatabase, $CoverColorsTable> {
  $$CoverColorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoverColorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoverColorsTable> {
  $$CoverColorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$CoverColorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoverColorsTable,
          CoverColorRow,
          $$CoverColorsTableFilterComposer,
          $$CoverColorsTableOrderingComposer,
          $$CoverColorsTableAnnotationComposer,
          $$CoverColorsTableCreateCompanionBuilder,
          $$CoverColorsTableUpdateCompanionBuilder,
          (
            CoverColorRow,
            BaseReferences<_$AppDatabase, $CoverColorsTable, CoverColorRow>,
          ),
          CoverColorRow,
          PrefetchHooks Function()
        > {
  $$CoverColorsTableTableManager(_$AppDatabase db, $CoverColorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoverColorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoverColorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoverColorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CoverColorsCompanion(key: key, color: color, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required int color,
                Value<int> rowid = const Value.absent(),
              }) => CoverColorsCompanion.insert(
                key: key,
                color: color,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoverColorsTable, CoverColorRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CoverColorsTable,
                    CoverColorRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoverColorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoverColorsTable,
      CoverColorRow,
      $$CoverColorsTableFilterComposer,
      $$CoverColorsTableOrderingComposer,
      $$CoverColorsTableAnnotationComposer,
      $$CoverColorsTableCreateCompanionBuilder,
      $$CoverColorsTableUpdateCompanionBuilder,
      (
        CoverColorRow,
        BaseReferences<_$AppDatabase, $CoverColorsTable, CoverColorRow>,
      ),
      CoverColorRow,
      PrefetchHooks Function()
    >;
typedef $$LyricsFilesTableCreateCompanionBuilder =
    LyricsFilesCompanion Function({
      required String trackId,
      required String path,
      Value<int> rowid,
    });
typedef $$LyricsFilesTableUpdateCompanionBuilder =
    LyricsFilesCompanion Function({
      Value<String> trackId,
      Value<String> path,
      Value<int> rowid,
    });

class $$LyricsFilesTableFilterComposer
    extends Composer<_$AppDatabase, $LyricsFilesTable> {
  $$LyricsFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LyricsFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LyricsFilesTable> {
  $$LyricsFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LyricsFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LyricsFilesTable> {
  $$LyricsFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);
}

class $$LyricsFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LyricsFilesTable,
          LyricsFileRow,
          $$LyricsFilesTableFilterComposer,
          $$LyricsFilesTableOrderingComposer,
          $$LyricsFilesTableAnnotationComposer,
          $$LyricsFilesTableCreateCompanionBuilder,
          $$LyricsFilesTableUpdateCompanionBuilder,
          (
            LyricsFileRow,
            BaseReferences<_$AppDatabase, $LyricsFilesTable, LyricsFileRow>,
          ),
          LyricsFileRow,
          PrefetchHooks Function()
        > {
  $$LyricsFilesTableTableManager(_$AppDatabase db, $LyricsFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LyricsFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LyricsFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LyricsFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LyricsFilesCompanion(
                trackId: trackId,
                path: path,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                required String path,
                Value<int> rowid = const Value.absent(),
              }) => LyricsFilesCompanion.insert(
                trackId: trackId,
                path: path,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LyricsFilesTable, LyricsFileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LyricsFilesTable,
                    LyricsFileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LyricsFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LyricsFilesTable,
      LyricsFileRow,
      $$LyricsFilesTableFilterComposer,
      $$LyricsFilesTableOrderingComposer,
      $$LyricsFilesTableAnnotationComposer,
      $$LyricsFilesTableCreateCompanionBuilder,
      $$LyricsFilesTableUpdateCompanionBuilder,
      (
        LyricsFileRow,
        BaseReferences<_$AppDatabase, $LyricsFilesTable, LyricsFileRow>,
      ),
      LyricsFileRow,
      PrefetchHooks Function()
    >;
typedef $$PlaysTableCreateCompanionBuilder = PlaysCompanion Function({
  Value<int> id,
  required String trackId,
  required DateTime playedAt,
  Value<int> listenedMs,
});
typedef $$PlaysTableUpdateCompanionBuilder = PlaysCompanion Function({
  Value<int> id,
  Value<String> trackId,
  Value<DateTime> playedAt,
  Value<int> listenedMs,
});

class $$PlaysTableFilterComposer extends Composer<_$AppDatabase, $PlaysTable> {
  $$PlaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaysTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaysTable> {
  $$PlaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaysTable> {
  $$PlaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => column,
  );
}

class $$PlaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaysTable,
          PlayRow,
          $$PlaysTableFilterComposer,
          $$PlaysTableOrderingComposer,
          $$PlaysTableAnnotationComposer,
          $$PlaysTableCreateCompanionBuilder,
          $$PlaysTableUpdateCompanionBuilder,
          (PlayRow, BaseReferences<_$AppDatabase, $PlaysTable, PlayRow>),
          PlayRow,
          PrefetchHooks Function()
        > {
  $$PlaysTableTableManager(_$AppDatabase db, $PlaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> listenedMs = const Value.absent(),
              }) => PlaysCompanion(
                id: id,
                trackId: trackId,
                playedAt: playedAt,
                listenedMs: listenedMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trackId,
                required DateTime playedAt,
                Value<int> listenedMs = const Value.absent(),
              }) => PlaysCompanion.insert(
                id: id,
                trackId: trackId,
                playedAt: playedAt,
                listenedMs: listenedMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaysTable, PlayRow>(table),
                  BaseReferences<_$AppDatabase, $PlaysTable, PlayRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaysTable,
      PlayRow,
      $$PlaysTableFilterComposer,
      $$PlaysTableOrderingComposer,
      $$PlaysTableAnnotationComposer,
      $$PlaysTableCreateCompanionBuilder,
      $$PlaysTableUpdateCompanionBuilder,
      (PlayRow, BaseReferences<_$AppDatabase, $PlaysTable, PlayRow>),
      PlayRow,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  required String id,
  required String name,
  required DateTime createdAt,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          PlaylistRow,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (
            PlaylistRow,
            BaseReferences<_$AppDatabase, $PlaylistsTable, PlaylistRow>,
          ),
          PlaylistRow,
          PrefetchHooks Function()
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, PlaylistRow>(table),
                  BaseReferences<_$AppDatabase, $PlaylistsTable, PlaylistRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      PlaylistRow,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (
        PlaylistRow,
        BaseReferences<_$AppDatabase, $PlaylistsTable, PlaylistRow>,
      ),
      PlaylistRow,
      PrefetchHooks Function()
    >;
typedef $$PlaylistTracksTableCreateCompanionBuilder =
    PlaylistTracksCompanion Function({
      required String playlistId,
      required String trackId,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$PlaylistTracksTableUpdateCompanionBuilder =
    PlaylistTracksCompanion Function({
      Value<String> playlistId,
      Value<String> trackId,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$PlaylistTracksTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaylistTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$PlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistTracksTable,
          PlaylistTrackRow,
          $$PlaylistTracksTableFilterComposer,
          $$PlaylistTracksTableOrderingComposer,
          $$PlaylistTracksTableAnnotationComposer,
          $$PlaylistTracksTableCreateCompanionBuilder,
          $$PlaylistTracksTableUpdateCompanionBuilder,
          (
            PlaylistTrackRow,
            BaseReferences<
              _$AppDatabase,
              $PlaylistTracksTable,
              PlaylistTrackRow
            >,
          ),
          PlaylistTrackRow,
          PrefetchHooks Function()
        > {
  $$PlaylistTracksTableTableManager(
    _$AppDatabase db,
    $PlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion(
                playlistId: playlistId,
                trackId: trackId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String trackId,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistTracksTable, PlaylistTrackRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlaylistTracksTable,
                    PlaylistTrackRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistTracksTable,
      PlaylistTrackRow,
      $$PlaylistTracksTableFilterComposer,
      $$PlaylistTracksTableOrderingComposer,
      $$PlaylistTracksTableAnnotationComposer,
      $$PlaylistTracksTableCreateCompanionBuilder,
      $$PlaylistTracksTableUpdateCompanionBuilder,
      (
        PlaylistTrackRow,
        BaseReferences<_$AppDatabase, $PlaylistTracksTable, PlaylistTrackRow>,
      ),
      PlaylistTrackRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$CoversTableTableManager get covers =>
      $$CoversTableTableManager(_db, _db.covers);
  $$CoverColorsTableTableManager get coverColors =>
      $$CoverColorsTableTableManager(_db, _db.coverColors);
  $$LyricsFilesTableTableManager get lyricsFiles =>
      $$LyricsFilesTableTableManager(_db, _db.lyricsFiles);
  $$PlaysTableTableManager get plays =>
      $$PlaysTableTableManager(_db, _db.plays);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(_db, _db.playlistTracks);
}
