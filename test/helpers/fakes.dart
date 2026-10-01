import 'dart:async';

import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/covers/di.dart';
import 'package:music_download_play_app/features/covers/domain/repositories/cover_repository.dart';
import 'package:music_download_play_app/features/downloads/di.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/downloads/domain/repositories/download_queue_repository.dart';
import 'package:music_download_play_app/features/home/di.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/home/domain/repositories/play_history_repository.dart';
import 'package:music_download_play_app/features/library/di.dart';
import 'package:music_download_play_app/features/library/domain/entities/import_result.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/repositories/library_repository.dart';
import 'package:music_download_play_app/features/player/di.dart';
import 'package:music_download_play_app/features/playlists/di.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_download_play_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_download_play_app/features/theme/di.dart';
import 'package:music_download_play_app/features/theme/domain/entities/theme_settings.dart';
import 'package:music_download_play_app/features/theme/domain/repositories/theme_settings_repository.dart';

/// 메모리 보관함.
class FakeLibraryRepository implements LibraryRepository {
  FakeLibraryRepository([List<Track> initial = const []])
    : _tracks = [...initial];

  final List<Track> _tracks;
  final _changes = StreamController<List<Track>>.broadcast();

  List<Track> get _sorted =>
      [..._tracks]..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  @override
  Stream<List<Track>> watchTracks() async* {
    yield _sorted;
    yield* _changes.stream;
  }

  @override
  Future<int> addTracks(List<Track> tracks) async {
    final uris = _tracks.map((t) => t.uri).toSet();
    final added = tracks.where((t) => uris.add(t.uri)).toList();
    _tracks.addAll(added);
    _changes.add(_sorted);
    return added.length;
  }
}

class FakeDeviceMusic implements DeviceMusicRepository {
  FakeDeviceMusic(this.result);

  ScanResult result;
  int calls = 0;

  @override
  Future<ScanResult> scan() async {
    calls++;
    return result;
  }
}

/// 파일 복사 없이 경로만 기억하는 커버 저장소.
class MemoryCoverRepository implements CoverRepository {
  final saved = <String, String>{};

  @override
  Future<Map<String, String>> loadAll() async => {...saved};

  @override
  Future<String> save(String key, String sourcePath) async =>
      saved[key] = sourcePath;

  @override
  Future<void> remove(String key) async => saved.remove(key);
}

class FakeImageSource implements CoverImageSource {
  FakeImageSource([this.result]);

  String? result;
  int calls = 0;

  @override
  Future<String?> pickFromDevice() async {
    calls++;
    return result;
  }
}

class MemoryThemeSettingsRepository implements ThemeSettingsRepository {
  MemoryThemeSettingsRepository([this.settings = const ThemeSettings()]);

  ThemeSettings settings;

  @override
  Future<ThemeSettings> load() async => settings;

  @override
  Future<void> savePreset(String presetId) async =>
      settings = ThemeSettings(presetId: presetId, mode: settings.mode);

  @override
  Future<void> saveMode(AppThemeMode mode) async =>
      settings = ThemeSettings(presetId: settings.presetId, mode: mode);
}

/// 메모리 재생 기록.
class MemoryPlayHistory implements PlayHistoryRepository {
  MemoryPlayHistory([List<PlayRecord> initial = const []])
    : plays = [...initial];

  final List<PlayRecord> plays;
  final _changes = StreamController<List<PlayRecord>>.broadcast();

  List<PlayRecord> get _sorted =>
      [...plays]..sort((a, b) => b.playedAt.compareTo(a.playedAt));

  @override
  Future<void> recordPlay(PlayRecord record) async {
    plays.add(record);
    _changes.add(_sorted);
  }

  @override
  Stream<List<PlayRecord>> watchPlays() async* {
    yield _sorted;
    yield* _changes.stream;
  }
}

/// 메모리 다운로드 대기열.
class MemoryDownloadQueue implements DownloadQueueRepository {
  MemoryDownloadQueue([List<DownloadItem> initial = const []])
    : items = [...initial];

  final List<DownloadItem> items;
  final _changes = StreamController<List<DownloadItem>>.broadcast();

  void set(List<DownloadItem> next) {
    items
      ..clear()
      ..addAll(next);
    _changes.add([...items]);
  }

  /// 받기 요청 기록.
  final requests = <DownloadRequest>[];

  @override
  Stream<List<DownloadItem>> watchQueue() async* {
    yield [...items];
    yield* _changes.stream;
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    requests.add(request);
    items.add(
      DownloadItem(
        id: 'q${requests.length}',
        title: request.title,
        artist: request.artist,
        genre: request.genre,
        playlistIds: request.playlistIds,
        status: DownloadStatus.queued,
      ),
    );
    _changes.add([...items]);
  }
}

/// 메모리 재생목록.
class MemoryPlaylistRepository implements PlaylistRepository {
  MemoryPlaylistRepository([List<Playlist> initial = const []])
    : lists = [...initial];

  final List<Playlist> lists;

  /// 재생목록 id → 들어 있는 곡 id.
  final members = <String, Set<String>>{};

  /// 재생목록 id → 고른 카드 색.
  final colors = <String, int?>{};
  final _changes = StreamController<List<Playlist>>.broadcast();

  List<Playlist> get _now => [
    for (final p in lists)
      Playlist(
        id: p.id,
        name: p.name,
        trackCount: members[p.id]?.length ?? p.trackCount,
        colorIndex: colors.containsKey(p.id) ? colors[p.id] : p.colorIndex,
        topTracks: p.topTracks,
        topArtists: p.topArtists,
      ),
  ];

  @override
  Stream<List<Playlist>> watchPlaylists() async* {
    yield _now;
    yield* _changes.stream;
  }

  @override
  Future<Playlist> create(String name) async {
    final made = Playlist(id: 'pl${lists.length + 1}', name: name);
    lists.add(made);
    _changes.add(_now);
    return made;
  }

  @override
  Future<void> addTrack(String trackId, Iterable<String> playlistIds) async {
    for (final id in playlistIds) {
      (members[id] ??= {}).add(trackId);
    }
    _changes.add(_now);
  }

  @override
  Future<void> setColor(String playlistId, int? colorIndex) async {
    colors[playlistId] = colorIndex;
    _changes.add(_now);
  }
}

/// 앱 전체를 띄우는 테스트용 의존성 (DB · 파일 · 권한 없이).
/// 각 기능의 실제 등록을 쓰고 리포지토리만 가짜로 바꾼다.
Future<void> setUpTestDependencies({
  List<Track> tracks = const [],
  DeviceMusicRepository? device,
  CoverRepository? covers,
  CoverImageSource? imageSource,
  ThemeSettings theme = const ThemeSettings(),
  PlayHistoryRepository? history,
  DownloadQueueRepository? downloads,
  PlaylistRepository? playlists,
}) async {
  await sl.reset();
  registerTheme(sl);
  registerLibrary(sl);
  registerCovers(sl);
  registerPlayer(sl);
  registerHome(sl);
  registerPlaylists(sl);
  registerDownloads(sl);
  sl.allowReassignment = true;
  sl
    ..registerLazySingleton<ThemeSettingsRepository>(
      () => MemoryThemeSettingsRepository(theme),
    )
    ..registerLazySingleton<LibraryRepository>(
      () => FakeLibraryRepository(tracks),
    )
    ..registerLazySingleton<DeviceMusicRepository>(
      () => device ?? FakeDeviceMusic(const ScanFound([])),
    )
    ..registerLazySingleton<CoverRepository>(
      () => covers ?? MemoryCoverRepository(),
    )
    ..registerLazySingleton<CoverImageSource>(
      () => imageSource ?? FakeImageSource(),
    )
    ..registerLazySingleton<PlayHistoryRepository>(
      () => history ?? MemoryPlayHistory(),
    )
    ..registerLazySingleton<DownloadQueueRepository>(
      () => downloads ?? MemoryDownloadQueue(),
    )
    ..registerLazySingleton<PlaylistRepository>(
      () => playlists ?? MemoryPlaylistRepository(),
    );
  sl.allowReassignment = false;
}
